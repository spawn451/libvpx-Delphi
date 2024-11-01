unit vp8cx;

{$ALIGN ON}
{$MINENUMSIZE 4}


interface

uses
  Windows,vpx_codec,vpx_encoder;

const
  DLL = 'libvpx.dll';

const
  // Algorithm Flags
  VP8_EFLAG_NO_REF_LAST = 1 shl 16;
  VP8_EFLAG_NO_REF_GF = 1 shl 17;
  VP8_EFLAG_NO_REF_ARF = 1 shl 21;
  VP8_EFLAG_NO_UPD_LAST = 1 shl 18;
  VP8_EFLAG_NO_UPD_GF = 1 shl 22;
  VP8_EFLAG_NO_UPD_ARF = 1 shl 23;
  VP8_EFLAG_FORCE_GF = 1 shl 19;
  VP8_EFLAG_FORCE_ARF = 1 shl 24;
  VP8_EFLAG_NO_UPD_ENTROPY = 1 shl 20;

  //VP8E_SET_SCREEN_CONTENT_MODE = 2;

type
  // Encoder control IDs
  vp8e_enc_control_id = (
    VP8E_SET_ROI_MAP = 8,
    VP8E_SET_ACTIVEMAP,
    VP8E_SET_SCALEMODE = 11,
    VP8E_SET_CPUUSED = 13,
    VP8E_SET_ENABLEAUTOALTREF,
    VP8E_SET_NOISE_SENSITIVITY,
    VP8E_SET_SHARPNESS,
    VP8E_SET_STATIC_THRESHOLD,
    VP8E_SET_TOKEN_PARTITIONS,
    VP8E_GET_LAST_QUANTIZER,
    VP8E_GET_LAST_QUANTIZER_64,
    VP8E_SET_ARNR_MAXFRAMES,
    VP8E_SET_ARNR_STRENGTH,
    VP8E_SET_ARNR_TYPE,
    VP8E_SET_TUNING,
    VP8E_SET_CQ_LEVEL,
    VP8E_SET_MAX_INTRA_BITRATE_PCT,
    VP8E_SET_FRAME_FLAGS,
    VP9E_SET_MAX_INTER_BITRATE_PCT,
    VP9E_SET_GF_CBR_BOOST_PCT,
    VP8E_SET_TEMPORAL_LAYER_ID,
    VP8E_SET_SCREEN_CONTENT_MODE,
    VP9E_SET_LOSSLESS,
    VP9E_SET_TILE_COLUMNS,
    VP9E_SET_TILE_ROWS,
    VP9E_SET_FRAME_PARALLEL_DECODING,
    VP9E_SET_AQ_MODE,
    VP9E_SET_FRAME_PERIODIC_BOOST,
    VP9E_SET_NOISE_SENSITIVITY,
    VP9E_SET_SVC,
    VP9E_SET_ROI_MAP,
    VP9E_SET_SVC_PARAMETERS,
    VP9E_SET_SVC_LAYER_ID,
    VP9E_SET_TUNE_CONTENT,
    VP9E_GET_SVC_LAYER_ID,
    VP9E_REGISTER_CX_CALLBACK,
    VP9E_SET_COLOR_SPACE,
    VP9E_SET_MIN_GF_INTERVAL = 48,
    VP9E_SET_MAX_GF_INTERVAL,
    VP9E_GET_ACTIVEMAP,
    VP9E_SET_COLOR_RANGE,
    VP9E_SET_SVC_REF_FRAME_CONFIG,
    VP9E_SET_RENDER_SIZE,
    VP9E_SET_TARGET_LEVEL,
    VP9E_SET_ROW_MT,
    VP9E_GET_LEVEL,
    VP9E_SET_ALT_REF_AQ,
    VP8E_SET_GF_CBR_BOOST_PCT,
    VP9E_ENABLE_MOTION_VECTOR_UNIT_TEST,
    VP9E_SET_SVC_INTER_LAYER_PRED,
    VP9E_SET_SVC_FRAME_DROP_LAYER,
    VP9E_GET_SVC_REF_FRAME_CONFIG,
    VP9E_SET_SVC_GF_TEMPORAL_REF,
    VP9E_SET_SVC_SPATIAL_LAYER_SYNC,
    VP9E_SET_TPL,
    VP9E_SET_POSTENCODE_DROP,
    VP9E_SET_DELTA_Q_UV,
    VP9E_SET_DISABLE_OVERSHOOT_MAXQ_CBR,
    VP9E_SET_DISABLE_LOOPFILTER,
    VP9E_SET_EXTERNAL_RATE_CONTROL,
    VP9E_SET_RTC_EXTERNAL_RATECTRL,
    VP9E_GET_LOOPFILTER_LEVEL,
    VP9E_GET_LAST_QUANTIZER_SVC_LAYERS,
    VP8E_SET_RTC_EXTERNAL_RATECTRL,
    VP9E_SET_QUANTIZER_ONE_PASS
  );

  // Scaling mode enum
  VPX_SCALING_MODE = (
    VP8E_NORMAL = 0,
    VP8E_FOURFIVE = 1,
    VP8E_THREEFIVE = 2,
    VP8E_ONETWO = 3
  );

  // Temporal layering mode
  VP9E_TEMPORAL_LAYERING_MODE = (
    VP9E_TEMPORAL_LAYERING_MODE_NOLAYERING = 0,
    VP9E_TEMPORAL_LAYERING_MODE_BYPASS = 1,
    VP9E_TEMPORAL_LAYERING_MODE_0101 = 2,
    VP9E_TEMPORAL_LAYERING_MODE_0212 = 3
  );

  // ROI map structure
  Pvpx_roi_map = ^vpx_roi_map_t;
  vpx_roi_map_t = record
    enabled: Byte;              // If ROI is enabled
    roi_map: PByte;            // ID between 0-3 (0-7 for VP9) for each region
    rows: Cardinal;            // Number of rows
    cols: Cardinal;            // Number of columns
    delta_q: array[0..7] of Integer;    // Quantizer deltas [-63, 63]
    delta_lf: array[0..7] of Integer;   // Loop filter deltas [-63, 63]
    skip: array[0..7] of Integer;       // Skip this block (VP9 only)
    ref_frame: array[0..7] of Integer;  // Reference frame for block (VP9)
    static_threshold: array[0..3] of Cardinal; // Static threshold (VP8 only)
  end;

  // Active map structure
  Pvpx_active_map = ^vpx_active_map_t;
  vpx_active_map_t = record
    active_map: PByte;         // 1 (on) or 0 (off) for each 16x16 region
    rows: Cardinal;            // number of rows
    cols: Cardinal;            // number of cols
  end;

  // Scaling mode structure
  Pvpx_scaling_mode = ^vpx_scaling_mode_t;
  vpx_scaling_mode_t = record
    h_scaling_mode: VPX_SCALING_MODE;  // horizontal scaling mode
    v_scaling_mode: VPX_SCALING_MODE;  // vertical scaling mode
  end;

  // Token partitions
  vp8e_token_partitions = (
    VP8_ONE_TOKENPARTITION = 0,
    VP8_TWO_TOKENPARTITION = 1,
    VP8_FOUR_TOKENPARTITION = 2,
    VP8_EIGHT_TOKENPARTITION = 3
  );

  // VP9 encoder content type
  vp9e_tune_content = (
    VP9E_CONTENT_DEFAULT,
    VP9E_CONTENT_SCREEN,
    VP9E_CONTENT_FILM,
    VP9E_CONTENT_INVALID
  );

  // Tuning options
  vp8e_tuning = (
    VP8_TUNE_PSNR,
    VP8_TUNE_SSIM
  );

  // Layer drop mode
  SVC_LAYER_DROP_MODE = (
    CONSTRAINED_LAYER_DROP,      // Upper layers constrained to drop if current layer drops
    LAYER_DROP,                  // Any spatial layer can drop
    FULL_SUPERFRAME_DROP,        // Only full superframe can drop
    CONSTRAINED_FROM_ABOVE_DROP  // Lower layers constrained to drop if current layer drops
  );

  type
  vpx_svc_layer_id_t = record
    spatial_layer_id: Integer;                                 // First spatial layer to start encoding
    temporal_layer_id: Integer;                               // Temporal layer id number (Deprecated)
    temporal_layer_id_per_spatial: array[0..VPX_SS_MAX_LAYERS-1] of Integer;  // Temp layer id
  end;

   Pvpx_svc_layer_id_t = ^vpx_svc_layer_id_t;

  type
    vpx_svc_ref_frame_config_t = record
      lst_fb_idx: array[0..VPX_SS_MAX_LAYERS-1] of Integer;         // Last buffer index
      gld_fb_idx: array[0..VPX_SS_MAX_LAYERS-1] of Integer;         // Golden buffer index
      alt_fb_idx: array[0..VPX_SS_MAX_LAYERS-1] of Integer;         // Altref buffer index
      update_buffer_slot: array[0..VPX_SS_MAX_LAYERS-1] of Integer; // Update reference frames
      // Following fields are deprecated
      update_last: array[0..VPX_SS_MAX_LAYERS-1] of Integer;        // Update last
      update_golden: array[0..VPX_SS_MAX_LAYERS-1] of Integer;      // Update golden
      update_alt_ref: array[0..VPX_SS_MAX_LAYERS-1] of Integer;     // Update altref
      reference_last: array[0..VPX_SS_MAX_LAYERS-1] of Integer;     // Last as reference
      reference_golden: array[0..VPX_SS_MAX_LAYERS-1] of Integer;   // Golden as reference
      reference_alt_ref: array[0..VPX_SS_MAX_LAYERS-1] of Integer;  // Altref as reference
      duration: array[0..VPX_SS_MAX_LAYERS-1] of Int64;             // Duration per spatial layer
    end;

   Pvpx_svc_ref_frame_config_t = ^vpx_svc_ref_frame_config_t;

  type

    vpx_svc_frame_drop_t = record
      framedrop_thresh: array[0..VPX_SS_MAX_LAYERS-1] of Integer;  // Frame drop thresholds
      framedrop_mode: SVC_LAYER_DROP_MODE;                         // Layer-based or constrained dropping
      max_consec_drop: Integer;                                    // Maximum consecutive drops, for any layer
    end;
    Pvpx_svc_frame_drop_t = ^vpx_svc_frame_drop_t;

  type
    vpx_svc_spatial_layer_sync_t = record
      spatial_layer_sync: array[0..VPX_SS_MAX_LAYERS-1] of Integer;  // Sync layer flags
      base_layer_intra_only: Integer;                                // Flag for setting Intra-only frame on base
    end;
    Pvpx_svc_spatial_layer_sync_t = ^vpx_svc_spatial_layer_sync_t;


var
  vpx_codec_vp8_cx_algo: vpx_codec_iface_t;
  vpx_codec_vp9_cx_algo: vpx_codec_iface_t;

function vpx_codec_vp8_cx(): Pvpx_codec_iface_t; cdecl; external DLL;
function vpx_codec_vp9_cx(): Pvpx_codec_iface_t; cdecl; external DLL;

// Control wrapper functions
function vpx_codec_control_VP8E_SET_ROI_MAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_roi_map_t): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_ACTIVEMAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_active_map_t): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_SCALEMODE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_scaling_mode_t): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_CPUUSED(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_ENABLEAUTOALTREF(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_NOISE_SENSITIVITY(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_SHARPNESS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_STATIC_THRESHOLD(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_TOKEN_PARTITIONS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP8E_GET_LAST_QUANTIZER(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
function vpx_codec_control_VP8E_GET_LAST_QUANTIZER_64(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_ARNR_MAXFRAMES(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_ARNR_STRENGTH(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_ARNR_TYPE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_TUNING(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vp8e_tuning): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_CQ_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_MAX_INTRA_BITRATE_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_FRAME_FLAGS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_MAX_INTER_BITRATE_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_GF_CBR_BOOST_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_TEMPORAL_LAYER_ID(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_SCREEN_CONTENT_MODE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_LOSSLESS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_TILE_COLUMNS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_TILE_ROWS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_FRAME_PARALLEL_DECODING(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_AQ_MODE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_FRAME_PERIODIC_BOOST(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_NOISE_SENSITIVITY(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_ROI_MAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_roi_map_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_PARAMETERS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Pointer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_LAYER_ID(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_layer_id_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_TUNE_CONTENT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vp9e_tune_content): vpx_codec_err_t;
function vpx_codec_control_VP9E_GET_SVC_LAYER_ID(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_layer_id_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_REGISTER_CX_CALLBACK(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Pointer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_COLOR_SPACE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_MIN_GF_INTERVAL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_MAX_GF_INTERVAL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_GET_ACTIVEMAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_active_map_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_COLOR_RANGE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_REF_FRAME_CONFIG(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_ref_frame_config_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_RENDER_SIZE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_TARGET_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_ROW_MT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_GET_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_ALT_REF_AQ(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_GF_CBR_BOOST_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_ENABLE_MOTION_VECTOR_UNIT_TEST(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_INTER_LAYER_PRED(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_FRAME_DROP_LAYER(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_frame_drop_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_GET_SVC_REF_FRAME_CONFIG(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_ref_frame_config_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_GF_TEMPORAL_REF(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_SVC_SPATIAL_LAYER_SYNC(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_spatial_layer_sync_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_TPL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_POSTENCODE_DROP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_DELTA_Q_UV(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_DISABLE_OVERSHOOT_MAXQ_CBR(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_DISABLE_LOOPFILTER(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
//function vpx_codec_control_VP9E_SET_EXTERNAL_RATE_CONTROL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_rc_funcs_t): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_RTC_EXTERNAL_RATECTRL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_GET_LOOPFILTER_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
function vpx_codec_control_VP9E_GET_LAST_QUANTIZER_SVC_LAYERS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
function vpx_codec_control_VP8E_SET_RTC_EXTERNAL_RATECTRL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
function vpx_codec_control_VP9E_SET_QUANTIZER_ONE_PASS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;

implementation

// Implementation of all wrapper functions
function vpx_codec_control_VP8E_SET_ROI_MAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_roi_map_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, data);
end;

function vpx_codec_control_VP8E_SET_ACTIVEMAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_active_map_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_SCALEMODE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_scaling_mode_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_CPUUSED(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_ENABLEAUTOALTREF(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_NOISE_SENSITIVITY(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_SHARPNESS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_STATIC_THRESHOLD(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_TOKEN_PARTITIONS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_GET_LAST_QUANTIZER(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_GET_LAST_QUANTIZER_64(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_ARNR_MAXFRAMES(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_ARNR_STRENGTH(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_ARNR_TYPE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_TUNING(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vp8e_tuning): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_CQ_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_MAX_INTRA_BITRATE_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_FRAME_FLAGS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_MAX_INTER_BITRATE_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
 begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_GF_CBR_BOOST_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
  begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_TEMPORAL_LAYER_ID(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_SCREEN_CONTENT_MODE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_LOSSLESS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_TILE_COLUMNS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_TILE_ROWS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_FRAME_PARALLEL_DECODING(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_AQ_MODE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_FRAME_PERIODIC_BOOST(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_NOISE_SENSITIVITY(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_ROI_MAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_roi_map_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_PARAMETERS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Pointer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_LAYER_ID(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_layer_id_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_TUNE_CONTENT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vp9e_tune_content): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, Integer(@data));
end;

function vpx_codec_control_VP9E_GET_SVC_LAYER_ID(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_layer_id_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_REGISTER_CX_CALLBACK(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Pointer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_COLOR_SPACE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_MIN_GF_INTERVAL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_MAX_GF_INTERVAL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_GET_ACTIVEMAP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_active_map_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_COLOR_RANGE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_REF_FRAME_CONFIG(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_ref_frame_config_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_RENDER_SIZE(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_TARGET_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_ROW_MT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_GET_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_ALT_REF_AQ(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_GF_CBR_BOOST_PCT(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_ENABLE_MOTION_VECTOR_UNIT_TEST(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_INTER_LAYER_PRED(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_FRAME_DROP_LAYER(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_frame_drop_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_GET_SVC_REF_FRAME_CONFIG(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_ref_frame_config_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_GF_TEMPORAL_REF(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_SVC_SPATIAL_LAYER_SYNC(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: vpx_svc_spatial_layer_sync_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_TPL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_POSTENCODE_DROP(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Cardinal): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_DELTA_Q_UV(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_DISABLE_OVERSHOOT_MAXQ_CBR(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_DISABLE_LOOPFILTER(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

{
function vpx_codec_control_VP9E_SET_EXTERNAL_RATE_CONTROL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Pvpx_rc_funcs_t): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, data);
end;
}

function vpx_codec_control_VP9E_SET_RTC_EXTERNAL_RATECTRL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_GET_LOOPFILTER_LEVEL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_GET_LAST_QUANTIZER_SVC_LAYERS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: PInteger): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP8E_SET_RTC_EXTERNAL_RATECTRL(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

function vpx_codec_control_VP9E_SET_QUANTIZER_ONE_PASS(ctx: vpx_codec_ctx_t; ctrl_id: Integer; data: Integer): vpx_codec_err_t;
begin
  Result := vpx_codec_control_(@ctx, ctrl_id, @data);
end;

end.
