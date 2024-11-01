unit vp8dx;

{$ALIGN ON}
{$MINENUMSIZE 4}

interface

uses
  Windows;

const
  DLL = 'libvpx.dll';

  VPX_DECODER_ABI_VERSION = 4;

  // Assuming VP8_DECODER_CTRL_ID_START is 0x800
  VP8_DECODER_CTRL_ID_START = $800;

type
  vpx_codec_iface_t = Pointer;
  vpx_codec_iter_t = Pointer;
  vpx_codec_err_t = Integer;

  vpx_codec_ctx_t = record
    // Define the structure as needed based on the C header
  end;
  Pvpx_codec_ctx_t = ^vpx_codec_ctx_t;

  // Decrypt callback function type
  vpx_decrypt_cb = procedure(decrypt_state: Pointer; input: PByte; output: PByte; count: Integer); cdecl;

  vpx_decrypt_init = record
    decrypt_cb: vpx_decrypt_cb;
    decrypt_state: Pointer;
  end;
  Pvpx_decrypt_init = ^vpx_decrypt_init;

  // Enum for VP8 decoder control functions
  vp8_dec_control_id = (
    VP8D_GET_LAST_REF_UPDATES = VP8_DECODER_CTRL_ID_START,
    VP8D_GET_FRAME_CORRUPTED,
    VP8D_GET_LAST_REF_USED,
    VPXD_SET_DECRYPTOR,
    VP8D_SET_DECRYPTOR, // Note: This is equal to VPXD_SET_DECRYPTOR
    VP9D_GET_FRAME_SIZE,
    VP9D_GET_DISPLAY_SIZE,
    VP9D_GET_BIT_DEPTH,
    VP9_SET_BYTE_ALIGNMENT,
    VP9_INVERT_TILE_DECODE_ORDER,
    VP9_SET_SKIP_LOOP_FILTER,
    VP9_DECODE_SVC_SPATIAL_LAYER,
    VPXD_GET_LAST_QUANTIZER,
    VP9D_SET_ROW_MT,
    VP9D_SET_LOOP_FILTER_OPT,
    VP8_DECODER_CTRL_ID_MAX
  );

// Function prototypes
function vpx_codec_vp8_dx: vpx_codec_iface_t; cdecl; external DLL;
function vpx_codec_vp9_dx: vpx_codec_iface_t; cdecl; external DLL;

function vpx_codec_dec_init_ver(ctx: Pvpx_codec_ctx_t; iface: vpx_codec_iface_t; cfg: Pointer; flags: Cardinal; ver: Integer): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_decode(ctx: Pvpx_codec_ctx_t; data: PByte; data_sz: Cardinal; user_priv: Pointer; deadline: Int64): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_get_frame(ctx: Pvpx_codec_ctx_t; iter: vpx_codec_iter_t): Pointer; cdecl; external DLL;
function vpx_codec_destroy(ctx: Pvpx_codec_ctx_t): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_control_(ctx: Pvpx_codec_ctx_t; ctrl_id: Integer): vpx_codec_err_t; cdecl; varargs; external DLL;

// Inline helper function declaration
function vpx_codec_dec_init(ctx: Pvpx_codec_ctx_t; iface: vpx_codec_iface_t; cfg: Pointer; flags: Cardinal): vpx_codec_err_t; inline;


implementation

// Inline helper function implementation
function vpx_codec_dec_init(ctx: Pvpx_codec_ctx_t; iface: vpx_codec_iface_t; cfg: Pointer; flags: Cardinal): vpx_codec_err_t; inline;
begin
  Result := vpx_codec_dec_init_ver(ctx, iface, cfg, flags, VPX_DECODER_ABI_VERSION);
end;


end.