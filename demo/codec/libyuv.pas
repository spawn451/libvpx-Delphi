unit libyuv;

interface

const
  DLL = 'libyuv.dll';


// Function declarations
function ARGBToI420(
  const src_argb: PByte;        // Source ARGB data
  src_stride_argb: Integer;     // Source stride (usually width * 4 for ARGB)
  dst_y: PByte;                 // Destination Y plane
  dst_stride_y: Integer;        // Y plane stride (usually width)
  dst_u: PByte;                 // Destination U plane
  dst_stride_u: Integer;        // U plane stride (usually width/2)
  dst_v: PByte;                 // Destination V plane
  dst_stride_v: Integer;        // V plane stride (usually width/2)
  width: Integer;               // Image width
  height: Integer              // Image height
): Integer; cdecl; external DLL;

function I420ToARGB(
  const src_y: PByte;          // Source Y plane
  src_stride_y: Integer;       // Y plane stride
  const src_u: PByte;          // Source U plane
  src_stride_u: Integer;       // U plane stride
  const src_v: PByte;          // Source V plane
  src_stride_v: Integer;       // V plane stride
  dst_argb: PByte;            // Destination ARGB buffer
  dst_stride_argb: Integer;    // Destination stride (width * 4)
  width: Integer;              // Image width
  height: Integer              // Image height
): Integer; cdecl; external DLL;

implementation

end.



