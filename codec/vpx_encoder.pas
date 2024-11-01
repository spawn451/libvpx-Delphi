unit vpx_encoder;

{$ALIGN ON}
{$MINENUMSIZE 4}

interface

uses
  Windows,vpx_codec;

const
  DLL = 'libvpx.dll';

  VPX_TS_MAX_PERIODICITY = 16;
  VPX_TS_MAX_LAYERS = 5;
  VPX_MAX_LAYERS = 12;  // 3 temporal + 4 spatial layers are allowed.
  VPX_SS_MAX_LAYERS = 5;
  VPX_SS_DEFAULT_LAYERS = 1;

    // Base ABI versions
  VPX_IMAGE_ABI_VERSION = 5;
  VPX_CODEC_ABI_VERSION = 4 + VPX_IMAGE_ABI_VERSION;  // = 9
  VPX_EXT_RATECTRL_ABI_VERSION = 7;  // From vpx_ext_ratectrl.h
  VPX_TPL_ABI_VERSION = 2;  // From vpx_tpl.h

  // ABI version constants
  VPX_ENCODER_ABI_VERSION = 16 + VPX_CODEC_ABI_VERSION +
                           VPX_EXT_RATECTRL_ABI_VERSION +
                           VPX_TPL_ABI_VERSION;

  // Capability flags
  VPX_CODEC_CAP_PSNR = $10000;
  VPX_CODEC_CAP_OUTPUT_PARTITION = $20000;

  // Usage flags
  VPX_CODEC_USE_PSNR = $10000;
  VPX_CODEC_USE_OUTPUT_PARTITION = $20000;
  VPX_CODEC_USE_HIGHBITDEPTH = $40000;

  // Frame flags
  VPX_FRAME_IS_KEY = $1;
  VPX_FRAME_IS_DROPPABLE = $2;
  VPX_FRAME_IS_INVISIBLE = $4;
  VPX_FRAME_IS_FRAGMENT = $8;

  // Error resilient flags
  VPX_ERROR_RESILIENT_DEFAULT = $1;
  VPX_ERROR_RESILIENT_PARTITIONS = $2;

  // Encoding flags
  VPX_EFLAG_FORCE_KF = 1 shl 0;

  // Deadline constants
  VPX_DL_REALTIME = 1;
  VPX_DL_GOOD_QUALITY = 1000000;
  VPX_DL_BEST_QUALITY = 0;

type
  // Forward declarations
  PvpxCodecCtx = Pointer;
  PvpxCodecIface = Pointer;
  PvpxImage = Pointer;

  size_t = NativeUInt;
  vpx_codec_pts_t = Int64;
  vpx_codec_frame_flags_t = Cardinal;
  vpx_codec_er_flags_t = Cardinal;
  vpx_enc_frame_flags_t = LongInt;
  vpx_codec_flags_t = Cardinal;

  // Define the iterator type and its pointer
  vpx_codec_iter_t = Pointer;
  Pvpx_codec_iter_t = ^vpx_codec_iter_t;

  // Fixed buffer structure
  PvpxFixedBuf = ^vpx_fixed_buf_t;
  vpx_fixed_buf_t = record
    buf: Pointer;
    sz: size_t;
  end;

  // Rational number structure
  PvpxRational = ^vpx_rational_t;
  vpx_rational_t = record
    num: Integer;
    den: Integer;
  end;

  // Packet kinds enumeration
  vpx_codec_cx_pkt_kind = (
    VPX_CODEC_CX_FRAME_PKT,
    VPX_CODEC_STATS_PKT,
    VPX_CODEC_FPMB_STATS_PKT,
    VPX_CODEC_PSNR_PKT,
    VPX_CODEC_CUSTOM_PKT = 256
  );

  // PSNR packet structure
  vpx_psnr_pkt = record
    samples: array[0..3] of Cardinal;
    sse: array[0..3] of UInt64;
    psnr: array[0..3] of Double;
  end;

  // Codec packet structure
  PvpxCodecCxPkt = ^vpx_codec_cx_pkt_t;
  vpx_codec_cx_pkt_t = record
    kind: vpx_codec_cx_pkt_kind;
    case Integer of
      0: (frame: record
            buf: Pointer;
            sz: size_t;
            pts: vpx_codec_pts_t;
            duration: Cardinal;
            flags: vpx_codec_frame_flags_t;
            partition_id: Integer;
            width: array[0..VPX_SS_MAX_LAYERS-1] of Cardinal;
            height: array[0..VPX_SS_MAX_LAYERS-1] of Cardinal;
            spatial_layer_encoded: array[0..VPX_SS_MAX_LAYERS-1] of Byte;
          end);
      1: (twopass_stats: vpx_fixed_buf_t);
      2: (firstpass_mb_stats: vpx_fixed_buf_t);
      3: (psnr: vpx_psnr_pkt);
      4: (raw: vpx_fixed_buf_t);
  end;

  // Callback function type
  vpx_codec_enc_output_cx_pkt_cb_fn_t = procedure(pkt: PvpxCodecCxPkt; user_data: Pointer); cdecl;

  // Callback pair structure
  PvpxCodecPrivOutputCxPktCbPair = ^vpx_codec_priv_output_cx_pkt_cb_pair_t;
  vpx_codec_priv_output_cx_pkt_cb_pair_t = record
    output_cx_pkt: vpx_codec_enc_output_cx_pkt_cb_fn_t;
    user_priv: Pointer;
  end;

  // Encoding pass enumeration
  vpx_enc_pass = (
    VPX_RC_ONE_PASS,
    VPX_RC_FIRST_PASS,
    VPX_RC_LAST_PASS
  );

  // Rate control mode enumeration
  vpx_rc_mode = (
    VPX_VBR,
    VPX_CBR,
    VPX_CQ,
    VPX_Q
  );

  // Keyframe mode enumeration
  vpx_kf_mode = (
    VPX_KF_FIXED,
    VPX_KF_AUTO,
    VPX_KF_DISABLED = 0
  );

  // Encoder configuration structure
  PvpxCodecEncCfg = ^vpx_codec_enc_cfg_t;
  vpx_codec_enc_cfg_t = record
    g_usage: Cardinal;
    g_threads: Cardinal;
    g_profile: Cardinal;
    g_w: Cardinal;
    g_h: Cardinal;
    g_bit_depth: Cardinal;
    g_input_bit_depth: Cardinal;
    g_timebase: vpx_rational_t;
    g_error_resilient: vpx_codec_er_flags_t;
    g_pass: vpx_enc_pass;
    g_lag_in_frames: Cardinal;
    rc_dropframe_thresh: Cardinal;
    rc_resize_allowed: Cardinal;
    rc_scaled_width: Cardinal;
    rc_scaled_height: Cardinal;
    rc_resize_up_thresh: Cardinal;
    rc_resize_down_thresh: Cardinal;
    rc_end_usage: vpx_rc_mode;
    rc_twopass_stats_in: vpx_fixed_buf_t;
    rc_firstpass_mb_stats_in: vpx_fixed_buf_t;
    rc_target_bitrate: Cardinal;
    rc_min_quantizer: Cardinal;
    rc_max_quantizer: Cardinal;
    rc_undershoot_pct: Cardinal;
    rc_overshoot_pct: Cardinal;
    rc_buf_sz: Cardinal;
    rc_buf_initial_sz: Cardinal;
    rc_buf_optimal_sz: Cardinal;
    rc_2pass_vbr_bias_pct: Cardinal;
    rc_2pass_vbr_minsection_pct: Cardinal;
    rc_2pass_vbr_maxsection_pct: Cardinal;
    rc_2pass_vbr_corpus_complexity: Cardinal;
    kf_mode: vpx_kf_mode;
    kf_min_dist: Cardinal;
    kf_max_dist: Cardinal;
    ss_number_layers: Cardinal;
    ss_enable_auto_alt_ref: array[0..VPX_SS_MAX_LAYERS-1] of Integer;
    ss_target_bitrate: array[0..VPX_SS_MAX_LAYERS-1] of Cardinal;
    ts_number_layers: Cardinal;
    ts_target_bitrate: array[0..VPX_TS_MAX_LAYERS-1] of Cardinal;
    ts_rate_decimator: array[0..VPX_TS_MAX_LAYERS-1] of Cardinal;
    ts_periodicity: Cardinal;
    ts_layer_id: array[0..VPX_TS_MAX_PERIODICITY-1] of Cardinal;
    layer_target_bitrate: array[0..VPX_MAX_LAYERS-1] of Cardinal;
    temporal_layering_mode: Integer;
    use_vizier_rc_params: Integer;
    active_wq_factor: vpx_rational_t;
    err_per_mb_factor: vpx_rational_t;
    sr_default_decay_limit: vpx_rational_t;
    sr_diff_factor: vpx_rational_t;
    kf_err_per_mb_factor: vpx_rational_t;
    kf_frame_min_boost_factor: vpx_rational_t;
    kf_frame_max_boost_first_factor: vpx_rational_t;
    kf_frame_max_boost_subs_factor: vpx_rational_t;
    kf_max_total_boost_factor: vpx_rational_t;
    gf_max_total_boost_factor: vpx_rational_t;
    gf_frame_max_boost_factor: vpx_rational_t;
    zm_factor: vpx_rational_t;
    rd_mult_inter_qp_fac: vpx_rational_t;
    rd_mult_arf_qp_fac: vpx_rational_t;
    rd_mult_key_qp_fac: vpx_rational_t;
  end;

  // SVC parameters structure
  PvpxSvcParameters = ^vpx_svc_parameters_t;
  vpx_svc_parameters_t = record
    max_quantizers: array[0..VPX_MAX_LAYERS-1] of Integer;
    min_quantizers: array[0..VPX_MAX_LAYERS-1] of Integer;
    scaling_factor_num: array[0..VPX_MAX_LAYERS-1] of Integer;
    scaling_factor_den: array[0..VPX_MAX_LAYERS-1] of Integer;
    speed_per_layer: array[0..VPX_MAX_LAYERS-1] of Integer;
    temporal_layering_mode: Integer;
    loopfilter_ctrl: array[0..VPX_MAX_LAYERS-1] of Integer;
  end;


// Function declarations
function vpx_codec_enc_init_ver(ctx: PvpxCodecCtx; iface: PvpxCodecIface;
  const cfg: PvpxCodecEncCfg; flags: vpx_codec_flags_t; ver: Integer): vpx_codec_err_t;
  cdecl; external DLL;

function vpx_codec_enc_init_multi_ver(ctx: PvpxCodecCtx; iface: PvpxCodecIface;
  cfg: PvpxCodecEncCfg; num_enc: Integer; flags: vpx_codec_flags_t;
  dsf: PvpxRational; ver: Integer): vpx_codec_err_t;
  cdecl; external DLL;

function vpx_codec_enc_config_default(iface: PvpxCodecIface; cfg: PvpxCodecEncCfg;
  usage: Cardinal): vpx_codec_err_t;
  cdecl; external DLL;

function vpx_codec_enc_config_set(ctx: PvpxCodecCtx; const cfg: PvpxCodecEncCfg): vpx_codec_err_t;
  cdecl; external DLL;

function vpx_codec_get_global_headers(ctx: PvpxCodecCtx): PvpxFixedBuf;
  cdecl; external DLL;

function vpx_codec_encode(ctx: PvpxCodecCtx; const img: PvpxImage;
  pts: vpx_codec_pts_t; duration: Cardinal; flags: vpx_enc_frame_flags_t;
  deadline: Cardinal): vpx_codec_err_t;
  cdecl; external DLL;

function vpx_codec_set_cx_data_buf(ctx: PvpxCodecCtx; const buf: PvpxFixedBuf;
  pad_before: Cardinal; pad_after: Cardinal): vpx_codec_err_t;
  cdecl; external DLL;

function vpx_codec_get_cx_data(ctx: PvpxCodecCtx; iter: Pvpx_codec_iter_t): PvpxCodecCxPkt;
  cdecl; external DLL;

function vpx_codec_get_preview_frame(ctx: PvpxCodecCtx): PvpxImage;
  cdecl; external DLL;

// Helper functions for initialization
function vpx_codec_enc_init(ctx: PvpxCodecCtx; iface: PvpxCodecIface;
  const cfg: PvpxCodecEncCfg; flags: vpx_codec_flags_t): vpx_codec_err_t;

function vpx_codec_enc_init_multi(ctx: PvpxCodecCtx; iface: PvpxCodecIface;
  cfg: PvpxCodecEncCfg; num_enc: Integer; flags: vpx_codec_flags_t;
  dsf: PvpxRational): vpx_codec_err_t;

implementation

function vpx_codec_enc_init(ctx: PvpxCodecCtx; iface: PvpxCodecIface;
  const cfg: PvpxCodecEncCfg; flags: vpx_codec_flags_t): vpx_codec_err_t;
begin
  Result := vpx_codec_enc_init_ver(ctx, iface, cfg, flags, VPX_ENCODER_ABI_VERSION);
end;

function vpx_codec_enc_init_multi(ctx: PvpxCodecCtx; iface: PvpxCodecIface;
  cfg: PvpxCodecEncCfg; num_enc: Integer; flags: vpx_codec_flags_t;
  dsf: PvpxRational): vpx_codec_err_t;
begin
  Result := vpx_codec_enc_init_multi_ver(ctx, iface, cfg, num_enc, flags, dsf, VPX_ENCODER_ABI_VERSION);
end;


end.
