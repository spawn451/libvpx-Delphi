unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,Vcl.StdCtrls, Vcl.ExtDlgs,VPXEncoder,VPXDecoder,
  Vcl.ExtCtrls;


type
  TForm1 = class(TForm)
    Button1: TButton;
    messagesLog: TMemo;
    Button2: TButton;
    ComboBox1: TComboBox;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    procedure Display(p_sender: String; p_message: string);
    function GetNow(): String;


  public
    { Public declarations }
    MonitorIndex: Integer;

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// *****************************************************************************
// PROCEDURE : Display()
// Display log messages
// *****************************************************************************

procedure TForm1.Display(p_sender: String; p_message: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      messagesLog.Lines.Add('[' + p_sender + '] - ' + GetNow() + ': ' +
        p_message);
    end);
end;
// .............................................................................

// *****************************************************************************
// FUNCTION : getNow()
// Get current DateTime
// *****************************************************************************
function TForm1.GetNow(): String;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;
// .............................................................................

// *****************************************************************************
// EVENT : OnCreate()
// On create form
// *****************************************************************************
procedure TForm1.FormCreate(Sender: TObject);
begin

  messagesLog.Clear;

end;
// .............................................................................

function GetScreenShot(MonitorIndex: Integer): TBitmap;
var
  Monitor: TMonitor;
  DC: HDC;
begin
  Result := TBitmap.Create;
  try
    Monitor := Screen.Monitors[MonitorIndex];
    Result.PixelFormat := pf32bit;
    Result.Width := Monitor.Width;
    Result.Height := Monitor.Height;
    DC := GetDC(0);
    try
      BitBlt(Result.Canvas.Handle, 0, 0, Result.Width, Result.Height, DC,
        Monitor.Left, Monitor.Top, SRCCOPY);
      Result.Modified := True;
    finally
      ReleaseDC(0, DC);
    end;
  except
    Result.Free;
    Result := nil;
  end;
end;
// .............................................................................


procedure TForm1.Button3Click(Sender: TObject);
begin
  // Set the default extension and filter for SaveDialog
  Self.SaveDialog1.DefaultExt := 'ivf';
  Self.SaveDialog1.Filter := 'IVF Files (*.ivf)|*.ivf';

  if Self.SaveDialog1.Execute then
  begin
    // If the user didn't type .ivf, it will be added automatically
    Self.Edit1.Text := Self.SaveDialog1.FileName;
  end;
end;

// *****************************************************************************
// PROCEDURE : Button1Click()
// Encode bitmap to IVF MemoryStream
// *****************************************************************************
procedure TForm1.Button1Click(Sender: TObject);
var
  Encoder: TVpxEncoder;
  EncodedStream: TMemoryStream;
  Bitmap: TBitmap;
  CodecType: TVpxCodecType;
  OutputFileName: string;
  FilePath: string;
begin
  try
    // Get the output filename from Edit1
    OutputFileName := Trim(Self.Edit1.Text);

    // Check if we have a filename
    if OutputFileName = '' then
    begin
      ShowMessage('Please select IVF output file.');
      Exit;
    end;

    // Check if user entered just a filename without path
    if ExtractFilePath(OutputFileName) = '' then
    begin
      ShowMessage('Please enter a complete path with filename.');
      Exit;
    end;

    // Ensure .ivf extension
    if LowerCase(ExtractFileExt(OutputFileName)) <> '.ivf' then
      OutputFileName := OutputFileName + '.ivf';

    // Validate the path exists
    FilePath := ExtractFilePath(OutputFileName);
    if not DirectoryExists(FilePath) then
    begin
      ShowMessage('The directory does not exist: ' + FilePath);
      Exit;
    end;

    // Get codec type from combo box
    if ComboBox1.ItemIndex = 0 then  // Assuming 0 is VP8
      CodecType := vctVP8
    else
      CodecType := vctVP9;

    // Create encoder with selected codec
    Encoder := TVpxEncoder.Create(CodecType);
    try
      Bitmap := GetScreenShot(0);
      try
        EncodedStream := Encoder.Encode(Bitmap);
        try
          EncodedStream.SaveToFile(OutputFileName);
          // Display appropriate message based on codec type
          if CodecType = vctVP8 then
            Display('INFO', 'Screenshot encoded with VP8 codec')
          else
            Display('INFO', 'Screenshot encoded with VP9 codec');
        finally
          EncodedStream.Free;
        end;
      finally
        Bitmap.Free;
      end;
    finally
      Encoder.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Error: ' + E.Message);
  end;
end;
// .............................................................................

procedure TForm1.Button4Click(Sender: TObject);
begin
  // Set the default extension and filter for SaveDialog
  Self.SaveDialog2.DefaultExt := 'bmp';
  Self.SaveDialog1.Filter := 'Bitmap Files (*.bmp)|*.bmp';

  if Self.SaveDialog2.Execute then
  begin
    // If the user didn't type .ivf, it will be added automatically
    Self.Edit2.Text := Self.SaveDialog2.FileName;
  end;
end;

// *****************************************************************************
// PROCEDURE : Button1Click()
// Decode IVF MemoryStream to bitmap
// *****************************************************************************
procedure TForm1.Button2Click(Sender: TObject);
var
  Decoder: TVpxDecoder;
  InputStream: TMemoryStream;
  OutputBitmap: TBitmap;
  OutputIVFFileName: string;
  OutputBMPFileName: string;
  IVFPath: string;
  BMPPath: string;
begin
  try
    // Get and validate IVF input filename from Edit1
    OutputIVFFileName := Trim(Self.Edit1.Text);
    if OutputIVFFileName = '' then
    begin
      ShowMessage('Please select IVF input file.');
      Exit;
    end;

    // Check if user entered just a filename without path for IVF
    if ExtractFilePath(OutputIVFFileName) = '' then
    begin
      ShowMessage('Please enter a complete path for IVF file.');
      Exit;
    end;

    // Ensure .ivf extension
    if LowerCase(ExtractFileExt(OutputIVFFileName)) <> '.ivf' then
      OutputIVFFileName := OutputIVFFileName + '.ivf';

    // Validate IVF path exists
    IVFPath := ExtractFilePath(OutputIVFFileName);
    if not DirectoryExists(IVFPath) then
    begin
      ShowMessage('The IVF directory does not exist: ' + IVFPath);
      Exit;
    end;

    // Check if IVF file exists
    if not FileExists(OutputIVFFileName) then
    begin
      ShowMessage('The IVF file does not exist: ' + OutputIVFFileName);
      Exit;
    end;

    // Get and validate BMP output filename from Edit2
    OutputBMPFileName := Trim(Self.Edit2.Text);
    if OutputBMPFileName = '' then
    begin
      ShowMessage('Please select BMP output file.');
      Exit;
    end;

    // Check if user entered just a filename without path for BMP
    if ExtractFilePath(OutputBMPFileName) = '' then
    begin
      ShowMessage('Please enter a complete path for BMP file.');
      Exit;
    end;

    // Ensure .bmp extension
    if LowerCase(ExtractFileExt(OutputBMPFileName)) <> '.bmp' then
      OutputBMPFileName := OutputBMPFileName + '.bmp';

    // Validate BMP path exists
    BMPPath := ExtractFilePath(OutputBMPFileName);
    if not DirectoryExists(BMPPath) then
    begin
      ShowMessage('The BMP directory does not exist: ' + BMPPath);
      Exit;
    end;

    // Proceed with decoding
    Decoder := TVpxDecoder.Create;
    try
      InputStream := TMemoryStream.Create;
      try
        InputStream.LoadFromFile(OutputIVFFileName);
        OutputBitmap := Decoder.Decode(InputStream);
        if Assigned(OutputBitmap) then
        begin
          try
            OutputBitmap.SaveToFile(OutputBMPFileName);
            Display('INFO', 'IVF file successfully decoded to BMP');
          finally
            OutputBitmap.Free;
          end;
        end
        else
        begin
          ShowMessage('Failed to decode IVF file.');
        end;
      finally
        InputStream.Free;
      end;
    finally
      Decoder.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Error: ' + E.Message);
  end;
end;
// .............................................................................







end.



