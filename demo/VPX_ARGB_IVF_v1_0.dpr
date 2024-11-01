program VPX_ARGB_IVF_v1_0;

uses
  Vcl.Forms,
  Main in 'Main.pas' {Form1},
  libyuv in 'codec\libyuv.pas',
  vp8cx in 'codec\vp8cx.pas',
  vp8dx in 'codec\vp8dx.pas',
  vpx_decoder in 'codec\vpx_decoder.pas',
  vpx_encoder in 'codec\vpx_encoder.pas',
  vpx_codec in 'codec\vpx_codec.pas',
  vpx_image in 'codec\vpx_image.pas',
  VPXEncoder in 'codec\VPXEncoder.pas',
  VPXDecoder in 'codec\VPXDecoder.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.


