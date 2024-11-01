unit vpx_codec;

{$ALIGN ON}
{$MINENUMSIZE 4}

interface

uses
  Windows,vpx_image;

const
  DLL = 'libvpx.dll';

  VPX_CODEC_ABI_VERSION = 4 + VPX_IMAGE_ABI_VERSION;

type
  // Error codes
  vpx_codec_err_t = (
    VPX_CODEC_OK,
    VPX_CODEC_ERR,
    VPX_CODEC_MEM_ERROR,
    VPX_CODEC_ABI_MISMATCH,
    VPX_CODEC_INCAPABLE,
    VPX_CODEC_UNSUP_BITSTREAM,
    VPX_CODEC_UNSUP_FEATURE,
    VPX_CODEC_CORRUPT_FRAME,
    VPX_CODEC_INVALID_PARAM,
    VPX_CODEC_LIST_END
  );

  // Capability and flag types
  vpx_codec_caps_t = LongInt;
  vpx_codec_flags_t = LongInt;

const
  // Codec capabilities
  VPX_CODEC_CAP_DECODER = $1;     // Is a decoder
  VPX_CODEC_CAP_ENCODER = $2;     // Is an encoder
  VPX_CODEC_CAP_HIGHBITDEPTH = $4;

type
  // Forward declarations
  vpx_codec_iface = record end;
  vpx_codec_iface_t = vpx_codec_iface;
  Pvpx_codec_iface_t = ^vpx_codec_iface_t;

  vpx_codec_priv = record end;
  vpx_codec_priv_t = vpx_codec_priv;
  Pvpx_codec_priv_t = ^vpx_codec_priv_t;

  vpx_codec_iter_t = Pointer;

  // Main codec context
  Pvpx_codec_ctx = ^vpx_codec_ctx_t;
  vpx_codec_ctx_t = record
    name: PAnsiChar;                    // Printable interface name
    iface: Pvpx_codec_iface_t;         // Interface pointers
    err: vpx_codec_err_t;              // Last returned error
    err_detail: PAnsiChar;             // Detailed error info
    init_flags: vpx_codec_flags_t;     // Flags passed at init time
    config: record
      case Integer of
        0: (dec: Pointer);             // Decoder Configuration Pointer
        1: (enc: Pointer);             // Encoder Configuration Pointer
        2: (raw: Pointer);
    end;
    priv: Pvpx_codec_priv_t;          // Algorithm private storage
  end;

  // Bit depth enumeration
  vpx_bit_depth_t = (
    VPX_BITS_8 = 8,    // 8 bits
    VPX_BITS_10 = 10,  // 10 bits
    VPX_BITS_12 = 12   // 12 bits
  );

// Version macros
function VPX_VERSION_MAJOR(v: Integer): Integer; inline;
function VPX_VERSION_MINOR(v: Integer): Integer; inline;
function VPX_VERSION_PATCH(v: Integer): Integer; inline;


function vpx_codec_version: Integer; cdecl; external DLL;
function vpx_codec_version_str: PAnsiChar; cdecl; external DLL;
function vpx_codec_version_extra_str: PAnsiChar; cdecl; external DLL;
function vpx_codec_build_config: PAnsiChar; cdecl; external DLL;
function vpx_codec_iface_name(iface: Pvpx_codec_iface_t): PAnsiChar; cdecl; external DLL;
function vpx_codec_err_to_string(err: vpx_codec_err_t): PAnsiChar; cdecl; external DLL;
function vpx_codec_error(ctx: Pvpx_codec_ctx): PAnsiChar; cdecl; external DLL;
function vpx_codec_error_detail(ctx: Pvpx_codec_ctx): PAnsiChar; cdecl; external DLL;
function vpx_codec_destroy(ctx: Pvpx_codec_ctx): vpx_codec_err_t; cdecl; external DLL;
function vpx_codec_get_caps(iface: Pvpx_codec_iface_t): vpx_codec_caps_t; cdecl; external DLL;
function vpx_codec_control_(ctx: Pvpx_codec_ctx; ctrl_id: Integer): vpx_codec_err_t; cdecl; varargs; external DLL;

implementation

// Inline functions implementation
function VPX_VERSION_MAJOR(v: Integer): Integer;
begin
  Result := (v shr 16) and $FF;
end;

function VPX_VERSION_MINOR(v: Integer): Integer;
begin
  Result := (v shr 8) and $FF;
end;

function VPX_VERSION_PATCH(v: Integer): Integer;
begin
  Result := v and $FF;
end;

// Helper functions for version information
function vpx_codec_version_major: Integer;
begin
  Result := VPX_VERSION_MAJOR(vpx_codec_version);
end;

function vpx_codec_version_minor: Integer;
begin
  Result := VPX_VERSION_MINOR(vpx_codec_version);
end;

function vpx_codec_version_patch: Integer;
begin
  Result := VPX_VERSION_PATCH(vpx_codec_version);
end;






end.
