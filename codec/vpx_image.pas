unit vpx_image;

{$ALIGN ON}
{$MINENUMSIZE 4}

interface


const
  DLL = 'libvpx.dll';

  VPX_IMAGE_ABI_VERSION = 5;


  VPX_IMG_FMT_PLANAR = $100;       // Image is a planar format
  VPX_IMG_FMT_UV_FLIP = $200;      // V plane precedes U in memory
  VPX_IMG_FMT_HAS_ALPHA = $400;    // Image has an alpha channel
  VPX_IMG_FMT_HIGHBITDEPTH = $800; // Image uses 16bit framebuffer

  // Image data pointers
  VPX_PLANE_PACKED = 0;  // To be used for all packed formats
  VPX_PLANE_Y = 0;       // Y (Luminance) plane
  VPX_PLANE_U = 1;       // U (Chroma) plane
  VPX_PLANE_V = 2;       // V (Chroma) plane
  VPX_PLANE_ALPHA = 3;   // A (Transparency) plane

// Brief List of supported image formats
type
  vpx_img_fmt = (
    VPX_IMG_FMT_NONE,
    VPX_IMG_FMT_YV12 = (VPX_IMG_FMT_PLANAR or VPX_IMG_FMT_UV_FLIP or 1),  // planar YVU
    VPX_IMG_FMT_I420 = (VPX_IMG_FMT_PLANAR or 2),
    VPX_IMG_FMT_I422 = (VPX_IMG_FMT_PLANAR or 5),
    VPX_IMG_FMT_I444 = (VPX_IMG_FMT_PLANAR or 6),
    VPX_IMG_FMT_I440 = (VPX_IMG_FMT_PLANAR or 7),
    VPX_IMG_FMT_NV12 = (VPX_IMG_FMT_PLANAR or 9),
    VPX_IMG_FMT_I42016 = (VPX_IMG_FMT_I420 or VPX_IMG_FMT_HIGHBITDEPTH),
    VPX_IMG_FMT_I42216 = (VPX_IMG_FMT_I422 or VPX_IMG_FMT_HIGHBITDEPTH),
    VPX_IMG_FMT_I44416 = (VPX_IMG_FMT_I444 or VPX_IMG_FMT_HIGHBITDEPTH),
    VPX_IMG_FMT_I44016 = (VPX_IMG_FMT_I440 or VPX_IMG_FMT_HIGHBITDEPTH)
  );
  vpx_img_fmt_t = vpx_img_fmt;  // alias for enum vpx_img_fmt



// Brief List of supported color spaces
type
  vpx_color_space = (
    VPX_CS_UNKNOWN = 0,        // Unknown
    VPX_CS_BT_601 = 1,         // BT.601
    VPX_CS_BT_709 = 2,         // BT.709
    VPX_CS_SMPTE_170 = 3,      // SMPTE.170
    VPX_CS_SMPTE_240 = 4,      // SMPTE.240
    VPX_CS_BT_2020 = 5,        // BT.2020
    VPX_CS_RESERVED = 6,       // Reserved
    VPX_CS_SRGB = 7            // sRGB
  );
  vpx_color_space_t = vpx_color_space;  // alias for enum vpx_color_space


// Brief List of supported color range
type
  vpx_color_range = (
    VPX_CR_STUDIO_RANGE = 0,   // Y  [16..235],  UV  [16..240]  (bit depth 8)
                               // Y  [64..940],  UV  [64..960]  (bit depth 10)
                               // Y [256..3760], UV [256..3840] (bit depth 12)
    VPX_CR_FULL_RANGE = 1      // YUV/RGB [0..255]  (bit depth 8)
                               // YUV/RGB [0..1023] (bit depth 10)
                               // YUV/RGB [0..4095] (bit depth 12)
  );
  vpx_color_range_t = vpx_color_range;  // alias for enum vpx_color_range

type
  // Main image structure
  Pvpx_image_t = ^vpx_image_t;

  // Brief Image Descriptor
  vpx_image_t = record

    fmt: vpx_img_fmt_t;       // Image Format
    cs: vpx_color_space_t;    // Color Space
    range: vpx_color_range_t; // Color Range

    // Image storage dimensions
    w: Cardinal;         // Stored image width
    h: Cardinal;         // Stored image height
    bit_depth: Cardinal; // Stored image bit-depth

    // Image display dimensions
    d_w: Cardinal;      // Displayed image width
    d_h: Cardinal;      // Displayed image height

    // Image intended rendering dimensions
    r_w: Cardinal;      // Intended rendering image width
    r_h: Cardinal;      // Intended rendering image height

    // Chroma subsampling info
    x_chroma_shift: Cardinal; // subsampling order, X
    y_chroma_shift: Cardinal; // subsampling order, Y

    // Image data pointers
    planes: array[0..3] of PByte;  // pointer to the top left pixel for each plane
    stride: array[0..3] of Integer; // stride between rows for each plane
    bps: Integer;                   // bits per sample (for packed formats)

    // User data pointer
    user_priv: Pointer;  // may be set by the application to associate data

    // Private members
    img_data: PByte;     // private
    img_data_owner: Integer; // private
    self_allocd: Integer;    // private
    fb_priv: Pointer;    // Frame buffer data associated with the image
  end;

  // Brief Representation of a rectangle on a surface

  vpx_image_rect_t = record
    x: Cardinal; // leftmost column
    y: Cardinal; // topmost row
    w: Cardinal; // width
    h: Cardinal; // height
  end;

// Function declarations
function vpx_img_alloc(img: Pvpx_image_t; fmt: vpx_img_fmt_t;
                      d_w, d_h: Cardinal; align: Cardinal): Pvpx_image_t;
  cdecl; external DLL name 'vpx_img_alloc';

function vpx_img_wrap(img: Pvpx_image_t; fmt: vpx_img_fmt_t;
                     d_w, d_h: Cardinal; stride_align: Cardinal;
                     img_data: PByte): Pvpx_image_t;
  cdecl; external DLL name 'vpx_img_wrap';

function vpx_img_set_rect(img: Pvpx_image_t; x, y, w, h: Cardinal): Integer;
  cdecl; external DLL name 'vpx_img_set_rect';

procedure vpx_img_flip(img: Pvpx_image_t);
  cdecl; external DLL name 'vpx_img_flip';

procedure vpx_img_free(img: Pvpx_image_t);
  cdecl; external DLL name 'vpx_img_free';

implementation

end.
