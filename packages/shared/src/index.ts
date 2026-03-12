// ContempAgent Shared Types -- API contracts and domain models

// --- Project Model -----------------------------------------------

export interface Project {
  readonly id: string;
  readonly name: string;
  readonly createdAt: string;
  readonly updatedAt: string;
  readonly width: number;
  readonly height: number;
  readonly frameRate: number;
  readonly duration: number;
  readonly tracks: readonly Track[];
}

export interface Track {
  readonly id: string;
  readonly type: TrackType;
  readonly name: string;
  readonly clips: readonly Clip[];
  readonly muted: boolean;
  readonly locked: boolean;
}

export type TrackType = 'video' | 'audio' | 'text' | 'image';

export interface Clip {
  readonly id: string;
  readonly trackId: string;
  readonly mediaRef: string;
  readonly startTime: number;
  readonly duration: number;
  readonly sourceOffset: number;
  readonly effects: readonly Effect[];
  readonly keyframes: readonly Keyframe[];
}

export interface Effect {
  readonly id: string;
  readonly type: EffectType;
  readonly params: Readonly<Record<string, number>>;
  readonly enabled: boolean;
}

export type EffectType =
  | 'brightness'
  | 'contrast'
  | 'saturation'
  | 'blur'
  | 'chromakey'
  | 'lut'
  | 'blend'
  | 'custom';

export interface Keyframe {
  readonly time: number;
  readonly property: string;
  readonly value: number;
  readonly easing: EasingType;
}

export type EasingType = 'linear' | 'ease-in' | 'ease-out' | 'ease-in-out' | 'bezier';

// --- Media -------------------------------------------------------

export interface MediaAsset {
  readonly id: string;
  readonly filename: string;
  readonly mimeType: string;
  readonly size: number;
  readonly duration?: number;
  readonly width?: number;
  readonly height?: number;
  readonly codec?: string;
  readonly thumbnailUrl?: string;
}

export interface CodecConfig {
  readonly codec: string;
  readonly width: number;
  readonly height: number;
  readonly bitrate: number;
  readonly frameRate: number;
}

export interface ExportSettings {
  readonly format: 'mp4' | 'webm' | 'gif';
  readonly quality: 'low' | 'medium' | 'high' | 'lossless';
  readonly codec: CodecConfig;
  readonly audioCodec?: string;
  readonly audioBitrate?: number;
}

// --- API Contracts -----------------------------------------------

export interface ApiResponse<T> {
  readonly success: boolean;
  readonly data?: T;
  readonly error?: ApiError;
}

export interface ApiError {
  readonly code: ErrorCode;
  readonly message: string;
  readonly details?: unknown;
}

export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'NOT_FOUND'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'CONFLICT'
  | 'INTERNAL_ERROR'
  | 'UPLOAD_FAILED'
  | 'TRANSCODE_FAILED'
  | 'EXPORT_FAILED'
  | 'CODEC_UNSUPPORTED'
  | 'FILE_TOO_LARGE'
  | 'RATE_LIMITED';

// --- Export Progress ---------------------------------------------

export interface ExportProgress {
  readonly jobId: string;
  readonly status: ExportStatus;
  readonly progress: number; // 0-100
  readonly currentStep: string;
  readonly estimatedTimeRemaining?: number; // seconds
  readonly outputUrl?: string;
  readonly error?: ApiError;
}

export type ExportStatus = 'queued' | 'processing' | 'encoding' | 'complete' | 'failed';
