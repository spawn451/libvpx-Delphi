unit VPXEncoder;

interface

uses
  Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Math, Vcl.StdCtrls,libyuv, vp8cx, vp8dx, vpx_decoder, vpx_encoder, vpx_codec, vpx_image;

type
  EVpxEncoderError = class(Exception);

type
  TVpxCodecType = (vctVP8, vctVP9);

  TVpxEncoderConfig = class
  private
    FConfig: vpx_codec_enc_cfg_t;
    FCodec: Pvpx_codec_ctx_t;
    FCodecType: TVpxCodecType;
  public
    constructor Create(Width, Height: Integer; ACodec: Pvpx_codec_ctx_t; ACodecType: TVpxCodecType = vctVP8);
    procedure ApplySettings;
    property Config: vpx_codec_enc_cfg_t read FConfig;
    property CodecType: TVpxCodecType read FCodecType;
  end;

  TImageConverter = class
  public
    class function BitmapToYUV420(const ABitmap: TBitmap): PByte;
  end;

  TIVFWriter = class
  private
    class var FCodecType: TVpxCodecType;
  public
    class procedure SetCodecType(ACodecType: TVpxCodecType);
    class procedure WriteHeader(AStream: TStream; Width, Height: Integer);
    class procedure WriteFrame(AStream: TStream; Data: Pointer; Size: Integer; Timestamp: Int64);
  end;

type
  TVpxEncoder = class
  private
    FCodec: vpx_codec_ctx_t;
    FConfig: TVpxEncoderConfig;
    FInitialized: Boolean;
    FCodecType: TVpxCodecType;
    FFrameCount: Int64;

    procedure InitializeEncoder;
    function EncodeFrame(const YuvData: PByte; Width, Height: Integer;
      Timestamp: Int64 = 0): TMemoryStream;
  public
    constructor Create(ACodecType: TVpxCodecType = vctVP8);
    destructor Destroy; override;
    function Encode(const ABitmap: TBitmap): TMemoryStream;
    property CodecType: TVpxCodecType read FCodecType write FCodecType;
  end;

implementation

{ ConvertToYUVUsingLibYUV }

function ConvertToYUVUsingLibYUV(BmpData: PByte; Width, Height: Integer): PByte;
var
  YUVSize: Integer;
  YUVData: PByte;
begin
  // Calculate YUV size: Y plane + U plane + V plane
  YUVSize := Width * Height * 3 div 2;

  // Allocate memory for YUV data
  GetMem(YUVData, YUVSize);

  if YUVData = nil then
  begin
    Result := nil;
    Exit;
  end;

  // Convert 32-bit RGBA to I420 (YUV 4:2:0)
  ARGBToI420(
    BmpData, Width * 4,                       // 32-bit data (RGBA)
    YUVData, Width,                           // Y plane
    YUVData + Width * Height, Width div 2,    // U plane
    YUVData + Width * Height + (Width div 2) * (Height div 2), Width div 2,  // V plane
    Width, Height
  );

  // Return the converted YUV data
  Result := YUVData;
end;

{ TVpxEncoderConfig }

constructor TVpxEncoderConfig.Create(Width, Height: Integer; ACodec: Pvpx_codec_ctx_t;
  ACodecType: TVpxCodecType = vctVP8);
var
  Res: vpx_codec_err_t;
  CodecIface: Pvpx_codec_iface_t;  // Changed to pointer type
begin
  inherited Create;
  FCodec := ACodec;
  FCodecType := ACodecType;

  // Select codec interface based on type
  case FCodecType of
    vctVP8: CodecIface := vpx_codec_vp8_cx();
    vctVP9: CodecIface := vpx_codec_vp9_cx();
  else
    raise EVpxEncoderError.Create('Invalid codec type');
  end;

  Res := vpx_codec_err_t(vpx_codec_enc_config_default(CodecIface, @FConfig, 0));
  if Res <> VPX_CODEC_OK then
    raise EVpxEncoderError.CreateFmt('Failed to get default encoder configuration: %s',
                                    [vpx_codec_err_to_string(Res)]);

  FConfig.g_w := Width;
  FConfig.g_h := Height;
  ApplySettings;
end;

procedure TVpxEncoderConfig.ApplySettings;
const
  kVp9I420ProfileNumber = 0;
begin
  with FConfig do
  begin
    case FCodecType of
      vctVP8:
      begin
        g_profile := 0;
      end;

      vctVP9:
      begin
        g_profile := kVp9I420ProfileNumber;
      end;
    end;

    // Common settings
    g_timebase.num := 1;
    g_timebase.den := 30;
    g_pass := VPX_RC_ONE_PASS;
    g_lag_in_frames := 0;
    //g_error_resilient := VPX_ERROR_RESILIENT_DEFAULT;

    // Performance settings
    g_threads := (Max(1, System.CPUCount + 1) div 2);
    rc_dropframe_thresh := 0;

    // Keyframe settings
    kf_min_dist := 10000;
    kf_max_dist := 10000;
    //kf_min_dist := g_timebase.den * 60;
    //kf_max_dist := g_timebase.den * 60;
    //kf_mode := VPX_KF_AUTO;


    // Bitrate and quality settings
    rc_target_bitrate := 10000;
    rc_end_usage := VPX_CBR;
    rc_undershoot_pct := 100;
    rc_overshoot_pct := 15;
    rc_min_quantizer := 10;
    rc_max_quantizer := 30;

  end;
end;

class function TImageConverter.BitmapToYUV420(const ABitmap: TBitmap): PByte;
var
  BmpData: PByte;
  Width, Height, Y: Integer;
  SrcLine, DstLine: PByte;
  BmpSize: Integer;
begin
  Result := nil;

  BmpData := nil;

  try
    Width := ABitmap.Width;
    Height := ABitmap.Height;
    BmpSize := Width * Height * 4;  // 4 bytes per pixel for 32-bit
    GetMem(BmpData, BmpSize);

    // Copy bitmap data line by line
    DstLine := BmpData;
    for Y := 0 to Height - 1 do
    begin
      SrcLine := ABitmap.ScanLine[Y];
      Move(SrcLine^, DstLine^, Width * 4);
      Inc(DstLine, Width * 4);
    end;

    // Convert 32-bit bitmap to YUV 4:2:0
    Result := ConvertToYUVUsingLibYUV(BmpData, Width, Height);
    if Result = nil then
      raise EVpxEncoderError.Create('Failed to convert frame to YUV');

  finally
    if Assigned(BmpData) then
      FreeMem(BmpData);
  end;
end;

{ TIVFWriter }

class procedure TIVFWriter.SetCodecType(ACodecType: TVpxCodecType);
begin
  FCodecType := ACodecType;
end;

class procedure TIVFWriter.WriteHeader(AStream: TStream; Width, Height: Integer);
var
  Header: packed record
    Signature: array[0..3] of AnsiChar;
    Version: Word;
    HeaderSize: Word;
    FourCC: Cardinal;
    Width: Word;
    Height: Word;
    TimebaseDen: Cardinal;
    TimebaseNum: Cardinal;
    NumFrames: Cardinal;
    Reserved: Cardinal;
  end;
begin
  FillChar(Header, SizeOf(Header), 0);
  Header.Signature := 'DKIF';
  Header.Version := 0;
  Header.HeaderSize := 32;

  // Set FourCC based on codec type
  case FCodecType of
    vctVP8: Header.FourCC := $30385056;  // 'VP80'
    vctVP9: Header.FourCC := $30395056;  // 'VP90'
  end;

  Header.Width := Width;
  Header.Height := Height;
  Header.TimebaseDen := 30;
  Header.TimebaseNum := 1;
  Header.NumFrames := 1;
  Header.Reserved := 0;

  AStream.WriteBuffer(Header, SizeOf(Header));
end;

class procedure TIVFWriter.WriteFrame(AStream: TStream; Data: Pointer; Size: Integer; Timestamp: Int64);
var
  i: Integer;
  ByteValue: Byte;
begin
  // Write frame size (4 bytes, little-endian)
  for i := 0 to 3 do
  begin
    ByteValue := (Size shr (i * 8)) and $FF;
    AStream.WriteBuffer(ByteValue, SizeOf(Byte));
  end;

  // Write timestamp (8 bytes, little-endian)
  for i := 0 to 7 do
  begin
    ByteValue := (Timestamp shr (i * 8)) and $FF;
    AStream.WriteBuffer(ByteValue, SizeOf(Byte));
  end;

  // Write the actual frame data
  AStream.WriteBuffer(Data^, Size);
end;
{ TVpxEncoder }

constructor TVpxEncoder.Create(ACodecType: TVpxCodecType = vctVP8);
begin
  inherited Create;
  FillChar(FCodec, SizeOf(FCodec), 0);
  FInitialized := False;
  FCodecType := ACodecType;
end;

destructor TVpxEncoder.Destroy;
begin
  if FInitialized then
    vpx_codec_destroy(@FCodec);
  FConfig.Free;
  inherited;
end;

procedure TVpxEncoder.InitializeEncoder;
const
kVp9AqModeCyclicRefresh = 3;
var
  Res: vpx_codec_err_t;
  CodecIface: Pvpx_codec_iface_t;  // Changed to pointer type
begin
  if not Assigned(FConfig) then
    raise EVpxEncoderError.Create('Encoder configuration not set');

  // Select codec interface based on type
  case FCodecType of
    vctVP8: CodecIface := vpx_codec_vp8_cx();
    vctVP9: CodecIface := vpx_codec_vp9_cx();
  else
    raise EVpxEncoderError.Create('Invalid codec type');
  end;

  Res := vpx_codec_err_t(vpx_codec_enc_init(@FCodec, CodecIface, @FConfig.Config, 0));
  if Res <> VPX_CODEC_OK then
    raise EVpxEncoderError.CreateFmt('Failed to initialize encoder: %s',
                                    [vpx_codec_err_to_string(Res)]);

  // Apply codec-specific controls
  case FCodecType of
    vctVP8:
    begin
      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP8E_SET_SCREEN_CONTENT_MODE), 1));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP8E_SET_SCREEN_CONTENT_MODE failed: %s',
                                        [vpx_codec_err_to_string(Res)]);

      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP8E_SET_NOISE_SENSITIVITY), 0));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('vpx_codec_control(VP8E_SET_NOISE_SENSITIVITY) failed: %s',
                                    [vpx_codec_err_to_string(Res)]);

      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP8E_SET_TOKEN_PARTITIONS), 3));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP8E_SET_TOKEN_PARTITIONS failed: %s',
                                        [vpx_codec_err_to_string(Res)]);

      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP8E_SET_CPUUSED), 16));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP8E_SET_CPUUSED failed: %s',
                                    [vpx_codec_err_to_string(Res)]);
    end;

    vctVP9:
    begin
      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP8E_SET_CPUUSED), 6));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP8E_SET_CPUUSED failed: %s',
                                    [vpx_codec_err_to_string(Res)]);


      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP9E_SET_TUNE_CONTENT), VP9E_CONTENT_SCREEN));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP9E_SET_TUNE_CONTENT failed: %s',
                                    [vpx_codec_err_to_string(Res)]);

      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP9E_SET_NOISE_SENSITIVITY), 0));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP9E_SET_NOISE_SENSITIVITY failed: %s',
                                    [vpx_codec_err_to_string(Res)]);

      Res := vpx_codec_err_t(vpx_codec_control_(@FCodec, Integer(VP9E_SET_AQ_MODE), kVp9AqModeCyclicRefresh));
      if Res <> VPX_CODEC_OK then
        raise EVpxEncoderError.CreateFmt('VP9E_SET_AQ_MODE failed: %s',
                                    [vpx_codec_err_to_string(Res)]);
    end;
  end;

  FInitialized := True;
end;

function TVpxEncoder.EncodeFrame(const YuvData: PByte; Width, Height: Integer;
  Timestamp: Int64): TMemoryStream;
var
  Raw: vpx_image_t;
  Res: vpx_codec_err_t;
  Pkt: PVpxCodecCxPkt;
  Iter: vpx_codec_iter_t;
  PacketFound: Boolean;
begin
  Result := TMemoryStream.Create;
  try
    if YuvData = nil then
      raise EVpxEncoderError.Create('YUV data is nil');

    if (Width <= 0) or (Height <= 0) then
      raise EVpxEncoderError.Create('Invalid dimensions');

    if not FInitialized then
      raise EVpxEncoderError.Create('Encoder not initialized');

    FillChar(Raw, SizeOf(Raw), 0);

    if vpx_img_wrap(@Raw, VPX_IMG_FMT_I420, Width, Height, 1, YuvData) = nil then
      raise EVpxEncoderError.Create('Failed to wrap YUV image');

    Res := vpx_codec_err_t(vpx_codec_encode(@FCodec, @Raw, Timestamp, 1, 0,
      VPX_DL_REALTIME));

    if Res <> VPX_CODEC_OK then
    begin
      var ErrorMsg := string(vpx_codec_error(@FCodec));
      var ErrorDetail := string(vpx_codec_error_detail(@FCodec));
      raise EVpxEncoderError.CreateFmt('Encode failed: %s. Details: %s',
        [ErrorMsg, ErrorDetail]);
    end;

    PacketFound := False;
    Iter := nil;

    try
      Pkt := vpx_codec_get_cx_data(@FCodec, @Iter);
      while Pkt <> nil do
      begin
        if Pkt^.kind = VPX_CODEC_CX_FRAME_PKT then
        begin
          if (Pkt^.frame.buf = nil) or (Pkt^.frame.sz = 0) then
            raise EVpxEncoderError.Create('Invalid packet data received');

          TIVFWriter.WriteFrame(Result, Pkt^.frame.buf, Pkt^.frame.sz,
            Pkt^.frame.pts);
          PacketFound := True;
        end;
        Pkt := vpx_codec_get_cx_data(@FCodec, @Iter);
      end;

      if not PacketFound then
        raise EVpxEncoderError.Create('No valid packets received from encoder');

    except
      on E: Exception do
        raise EVpxEncoderError.CreateFmt('Error processing encoded frame: %s', [E.Message]);
    end;

    Result.Position := 0;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TVpxEncoder.Encode(const ABitmap: TBitmap): TMemoryStream;
var
  YuvData: PByte;
  EncodedFrame: TMemoryStream;
begin
  Result := nil;
  YuvData := nil;

  if ABitmap = nil then
    raise EVpxEncoderError.Create('Input bitmap is nil');

  if ABitmap.PixelFormat <> pf32bit then
    raise EVpxEncoderError.Create('Bitmap must be 32-bit format');

  try
    // Check if we need to reinitialize the encoder due to size change
    if Assigned(FConfig) and
       ((FConfig.Config.g_w <> ABitmap.Width) or
        (FConfig.Config.g_h <> ABitmap.Height)) then
    begin
      // Size changed - need to reinitialize
      if FInitialized then
        vpx_codec_destroy(@FCodec);
      FConfig.Free;
      FConfig := nil;
      FInitialized := False;
    end;

    // Create and initialize encoder if needed
    if not Assigned(FConfig) then
    begin
      FConfig := TVpxEncoderConfig.Create(ABitmap.Width, ABitmap.Height, @FCodec, FCodecType);
      InitializeEncoder;
    end;

    // Set the codec type for IVF writer
    TIVFWriter.SetCodecType(FCodecType);

    // Convert bitmap to YUV
    YuvData := TImageConverter.BitmapToYUV420(ABitmap);
    if not Assigned(YuvData) then
      raise EVpxEncoderError.Create('YUV conversion failed');

    // Create output stream and write IVF header
    Result := TMemoryStream.Create;
    try
      TIVFWriter.WriteHeader(Result, ABitmap.Width, ABitmap.Height);

      // Encode frame and copy to result stream
      EncodedFrame := EncodeFrame(YuvData, ABitmap.Width, ABitmap.Height, FFrameCount);
      try
        Result.CopyFrom(EncodedFrame, 0);
        Result.Position := 0;
        Inc(FFrameCount);
      finally
        EncodedFrame.Free;
      end;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    if Assigned(YuvData) then
      FreeMem(YuvData);
  end;
end;

end.

