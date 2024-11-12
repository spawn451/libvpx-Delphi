unit vpx_decoder;

{$ALIGN ON}
{$MINENUMSIZE 4}

interface

uses
  windows,vpx_image;

const
  DLL = 'libvpx.dll';

  VPX_IMAGE_ABI_VERSION = 5;
  VPX_CODEC_ABI_VERSION = 4 + VPX_IMAGE_ABI_VERSION;

  VPX_DECODER_ABI_VERSION = 3 + VPX_CODEC_ABI_VERSION;

  // Decoder capabilities
  VPX_CODEC_CAP_PUT_SLICE = $10000;
  VPX_CODEC_CAP_PUT_FRAME = $20000;
  VPX_CODEC_CAP_POSTPROC = $40000;
  VPX_CODEC_CAP_ERROR_CONCEALMENT = $80000;
  VPX_CODEC_CAP_INPUT_FRAGMENTS = $100000;
  VPX_CODEC_CAP_FRAME_THREADING = $200000;
  VPX_CODEC_CAP_EXTERNAL_FRAME_BUFFER = $400000;

  // Initialization-time feature enabling
  VPX_CODEC_USE_POSTPROC = $10000;
  VPX_CODEC_USE_ERROR_CONCEALMENT = $20000;
  VPX_CODEC_USE_INPUT_FRAGMENTS = $40000;
  VPX_CODEC_USE_FRAME_THREADING = $80000;

type
  vpx_codec_iface_t = Pointer;
  vpx_codec_ctx_t = Pointer;
  vpx_codec_iter_t = Pointer;
  vpx_codec_err_t = Integer;
  vpx_codec_flags_t = UInt32;

  vpx_codec_stream_info_t = record
    sz: Cardinal;
    w: Cardinal;
    h: Cardinal;
    is_kf: Cardinal;
  end;
  Pvpx_codec_stream_info_t = ^vpx_codec_stream_info_t;

  vpx_codec_dec_cfg_t = record
    threads: Cardinal;
    w: Cardinal;
    h: Cardinal;
  end;
  Pvpx_codec_dec_cfg_t = ^vpx_codec_dec_cfg_t;

  vpx_image_t = record
    // Define the structure as needed based on the C header
  end;

  Pvpx_image_rect_t = ^vpx_image_rect_t;

  vpx_codec_put_frame_cb_fn_t = procedure(user_priv: Pointer; img: Pvpx_image_t); cdecl;
  vpx_codec_put_slice_cb_fn_t = procedure(user_priv: Pointer; img: Pvpx_image_t; valid, update: Pvpx_image_rect_t); cdecl;

  vpx_get_frame_buffer_cb_fn_t = function(priv: Pointer; min_size: size_t; align: size_t): Integer; cdecl;
  vpx_release_frame_buffer_cb_fn_t = function(priv: Pointer; fb: Pointer): Integer; cdecl;

// Function prototypes
function vpx_codec_dec_init_ver(ctx: vpx_codec_ctx_t; iface: vpx_codec_iface_t; cfg: Pvpx_codec_dec_cfg_t; flags: vpx_codec_flags_t; ver: Integer): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_peek_stream_info(iface: vpx_codec_iface_t; data: PByte; data_sz: Cardinal; si: Pvpx_codec_stream_info_t): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_get_stream_info(ctx: vpx_codec_ctx_t; si: Pvpx_codec_stream_info_t): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_decode(ctx: vpx_codec_ctx_t; data: PByte; data_sz: Cardinal; user_priv: Pointer; deadline: LongInt): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_get_frame(ctx: vpx_codec_ctx_t; iter: vpx_codec_iter_t): Pvpx_image_t; cdecl; external DLL;
function vpx_codec_register_put_frame_cb(ctx: vpx_codec_ctx_t; cb: vpx_codec_put_frame_cb_fn_t; user_priv: Pointer): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_register_put_slice_cb(ctx: vpx_codec_ctx_t; cb: vpx_codec_put_slice_cb_fn_t; user_priv: Pointer): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_set_frame_buffer_functions(ctx: vpx_codec_ctx_t; cb_get: vpx_get_frame_buffer_cb_fn_t; cb_release: vpx_release_frame_buffer_cb_fn_t; cb_priv: Pointer): vpx_codec_err_t; cdecl; external DLL;

// Inline helper function declaration
function vpx_codec_dec_init(ctx: vpx_codec_ctx_t; iface: vpx_codec_iface_t; cfg: Pvpx_codec_dec_cfg_t; flags: vpx_codec_flags_t): vpx_codec_err_t; inline;

implementation

// Inline helper function implementation
function vpx_codec_dec_init(ctx: vpx_codec_ctx_t; iface: vpx_codec_iface_t; cfg: Pvpx_codec_dec_cfg_t; flags: vpx_codec_flags_t): vpx_codec_err_t; inline;
begin
  Result := vpx_codec_dec_init_ver(ctx, iface, cfg, flags, VPX_DECODER_ABI_VERSION);
end;

end.
