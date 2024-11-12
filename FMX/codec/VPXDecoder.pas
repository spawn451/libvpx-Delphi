unit VPXDecoder;

interface

uses
  System.SysUtils, System.Classes, FMX.Graphics, System.UITypes,
  libyuv, vp8dx, vpx_decoder, vpx_image, vpx_codec;

const
  IVF_SIGNATURE: array[0..3] of AnsiChar = 'DKIF';

type
  // IVF file header structure
  TIVFFileHeader = packed record
    Signature: array[0..3] of AnsiChar;
    Version: Word;
    HeaderSize: Word;
    FourCC: Cardinal;
    Width: Word;
    Height: Word;
    TimebaseNumerator: Cardinal;
    TimebaseDenominator: Cardinal;
    NumberOfFrames: Cardinal;
    Unused: Cardinal;
  end;

  // IVF frame header structure
  TIVFFrameHeader = packed record
    FrameSize: Cardinal;
    Timestamp: UInt64;
  end;

  // Custom exception type
  EVpxDecoderError = class(Exception);

  // Reader class for IVF format
  TIVFReader = class
  private
    class function ReadLE32(Stream: TMemoryStream): Cardinal;
    class function ReadLE64(Stream: TMemoryStream): UInt64;
  public
  class function ReadHeader(AStream: TMemoryStream; out Width, Height: Word;
  out FourCC: Cardinal): Boolean;
    class function ReadFrame(AStream: TMemoryStream; out Data: TBytes; out Timestamp: UInt64): Boolean;
  end;

  // Image conversion helper class
  TImageConverter = class
  public
    class procedure YUVToARGB(const Img: Pvpx_image_t; Width, Height: Integer;
      const Bitmap: TBitmap);
  end;

  // Main decoder class
type
  TVpxDecoder = class
  private
    FCodec: vpx_codec_ctx_t;
    FInitialized: Boolean;
    FFourCC: Cardinal;

    procedure InitializeDecoder(Width, Height: Integer; FourCC: Cardinal);
    function DecodeFrame(const EncodedData: TBytes): Pvpx_image_t;
  public
    constructor Create;
    destructor Destroy; override;
    function Decode(InputMemStream: TMemoryStream): TBitmap;
  end;

implementation

{ TIVFReader }

function get_vpx_decoder_by_fourcc(fourcc: Cardinal): Pvpx_codec_iface_t;
begin
  case fourcc of
    $30385056:  // 'VP80'
      Result := vpx_codec_vp8_dx();
    $30395056:  // 'VP90'
      Result := vpx_codec_vp9_dx();
    else
      Result := nil;
  end;
end;

class function TIVFReader.ReadLE32(Stream: TMemoryStream): Cardinal;
var
  Buffer: array[0..3] of Byte;
begin
  Stream.ReadBuffer(Buffer, 4);
  Result := Buffer[0] or
            (Cardinal(Buffer[1]) shl 8) or
            (Cardinal(Buffer[2]) shl 16) or
            (Cardinal(Buffer[3]) shl 24);
end;

class function TIVFReader.ReadLE64(Stream: TMemoryStream): UInt64;
var
  Buffer: array[0..7] of Byte;
begin
  Stream.ReadBuffer(Buffer, 8);
  Result := Buffer[0] or
            (UInt64(Buffer[1]) shl 8) or
            (UInt64(Buffer[2]) shl 16) or
            (UInt64(Buffer[3]) shl 24) or
            (UInt64(Buffer[4]) shl 32) or
            (UInt64(Buffer[5]) shl 40) or
            (UInt64(Buffer[6]) shl 48) or
            (UInt64(Buffer[7]) shl 56);
end;

class function TIVFReader.ReadHeader(AStream: TMemoryStream; out Width, Height: Word;
  out FourCC: Cardinal): Boolean;
var
  Header: TIVFFileHeader;
  Signature: array[0..3] of AnsiChar;
begin
  Result := False;

  if AStream.Size < SizeOf(TIVFFileHeader) then
    Exit;

  AStream.Position := 0;
  AStream.ReadBuffer(Header, SizeOf(TIVFFileHeader));

  Move(Header.Signature, Signature, 4);
  if not CompareMem(@Signature, @IVF_SIGNATURE, 4) then
    Exit;

  Width := Header.Width;
  Height := Header.Height;
  FourCC := Header.FourCC;
  Result := True;
end;

class function TIVFReader.ReadFrame(AStream: TMemoryStream;
  out Data: TBytes; out Timestamp: UInt64): Boolean;
var
  FrameSize: Cardinal;
begin
  Result := False;

  if AStream.Position >= AStream.Size then
    Exit;

  // Read frame size and timestamp
  FrameSize := ReadLE32(AStream);
  Timestamp := ReadLE64(AStream);

  // Read frame data
  SetLength(Data, FrameSize);
  AStream.ReadBuffer(Data[0], FrameSize);

  Result := True;
end;

{ TImageConverter }

class procedure TImageConverter.YUVToARGB(const Img: Pvpx_image_t;
  Width, Height: Integer; const Bitmap: TBitmap);
var
  Y: Integer;
  BitmapData: TBitmapData;
  RGBData: PByte;
begin
  if not Assigned(Img) or not Assigned(Bitmap) then
    raise EVpxDecoderError.Create('Invalid image conversion parameters');

  GetMem(RGBData, Width * Height * 4);
  try
    // Convert YUV to ARGB
    if I420ToARGB(
      Img^.planes[0], Img^.stride[0],    // Y
      Img^.planes[1], Img^.stride[1],    // U
      Img^.planes[2], Img^.stride[2],    // V
      RGBData, Width * 4,                // ARGB output
      Width, Height) <> 0 then
      raise EVpxDecoderError.Create('YUV to ARGB conversion failed');

    // Configure bitmap
    Bitmap.Width := Width;
    Bitmap.Height := Height;

    // Map bitmap data
    if not Bitmap.Map(TMapAccess.Write, BitmapData) then
      raise EVpxDecoderError.Create('Failed to map bitmap data');
    try
      // Copy data to bitmap
      for Y := 0 to Height - 1 do
      begin
        Move(RGBData[Y * Width * 4],
             PByte(BitmapData.GetScanline(Y))^,
             Width * 4);
      end;
    finally
      Bitmap.Unmap(BitmapData);
    end;
  finally
    FreeMem(RGBData);
  end;
end;

{ TVpxDecoder }

constructor TVpxDecoder.Create;
begin
  inherited Create;
  FillChar(FCodec, SizeOf(FCodec), 0);
  FInitialized := False;
end;

destructor TVpxDecoder.Destroy;
begin
  if FInitialized then
    vpx_codec_destroy(@FCodec);
  inherited;
end;

procedure TVpxDecoder.InitializeDecoder(Width, Height: Integer; FourCC: Cardinal);
var
  Cfg: vpx_codec_dec_cfg_t;
  Res: vpx_codec_err_t;
  CodecInterface: Pvpx_codec_iface_t;
begin
  if FInitialized then
    Exit;

  FFourCC := FourCC;
  CodecInterface := get_vpx_decoder_by_fourcc(FourCC);
  if CodecInterface = nil then
    raise EVpxDecoderError.Create('Unsupported codec format');

  FillChar(Cfg, SizeOf(Cfg), 0);
  Cfg.threads := 1;
  Cfg.w := Width;
  Cfg.h := Height;

  Res := vpx_codec_err_t(vpx_codec_dec_init(@FCodec, CodecInterface, @Cfg, 0));
  if Res <> VPX_CODEC_OK then
    raise EVpxDecoderError.CreateFmt('Failed to initialize decoder: %s',
      [vpx_codec_err_to_string(Res)]);

  FInitialized := True;
end;

function TVpxDecoder.DecodeFrame(const EncodedData: TBytes): Pvpx_image_t;
var
  Res: vpx_codec_err_t;
  Iter: vpx_codec_iter_t;
begin
  Res := vpx_codec_err_t(vpx_codec_decode(@FCodec, @EncodedData[0],
    Length(EncodedData), nil, 0));
  if Res <> VPX_CODEC_OK then
    raise EVpxDecoderError.CreateFmt('Failed to decode frame: %s',
      [vpx_codec_err_to_string(Res)]);

  Iter := nil;
  Result := vpx_codec_get_frame(@FCodec, @Iter);
  if Result = nil then
    raise EVpxDecoderError.Create('Failed to get decoded frame');
end;

function TVpxDecoder.Decode(InputMemStream: TMemoryStream): TBitmap;
var
  Width, Height: Word;
  FourCC: Cardinal;
  FrameData: TBytes;
  Timestamp: UInt64;
  DecodedImage: Pvpx_image_t;
begin
  Result := nil;

  // Read and validate IVF header
  if not TIVFReader.ReadHeader(InputMemStream, Width, Height, FourCC) then
    raise EVpxDecoderError.Create('Invalid IVF file format');

  // Initialize decoder with detected codec
  InitializeDecoder(Width, Height, FourCC);

  // Read frame
  if not TIVFReader.ReadFrame(InputMemStream, FrameData, Timestamp) then
    raise EVpxDecoderError.Create('Failed to read frame data');

  try
    // Decode frame
    DecodedImage := DecodeFrame(FrameData);

    // Convert to bitmap
    Result := TBitmap.Create;
    try
      TImageConverter.YUVToARGB(DecodedImage, Width, Height, Result);
    except
      Result.Free;
      Result := nil;
      raise;
    end;
  except
    on E: Exception do
    begin
      if Assigned(Result) then
      begin
        Result.Free;
        Result := nil;
      end;
      raise EVpxDecoderError.Create('Decoding failed: ' + E.Message);
    end;
  end;
end;

end.
