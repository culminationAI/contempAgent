# ContempAgent v0.1 — Auto Memory

## Current State

- **Version**: v0.1 (2026-03-13)
- **Stack**: TypeScript strict + GLSL + React + WebGL2 + WebCodecs + Node.js + Express + FFmpeg
- **Target**: Clideo-like browser video editor (https://clideo.com/editor/)
- **Status**: Project initialized, architecture defined, no application code yet

## Architecture

- **Pattern**: Studio (state management) / Compositor (WebGL2 rendering engine)
- **Key insight**: GPU-to-CPU memory copies are the biggest bottleneck — keep data on GPU throughout pipeline
- **Rendering**: WebGL2 required — FBO per track, GLSL shader chain, blend pass compositing
- **Decode**: WebCodecs VideoDecoder for precise frame extraction (not `<video>` element)
- **Export**: WebCodecs VideoEncoder client-side + FFmpeg server-side fallback

## Reference Libraries

| Library | Use Case | Notes |
|---------|----------|-------|
| **Etro** | TypeScript + GLSL reference | Cleanest API: layers, effects, `movie.record()` |
| **OpenVideo** | Architecture reference | Studio/Compositor pattern, React + WebCodecs + PixiJS |
| **BBC VideoContext** | WebGL compositing reference | Graph-based, EffectNode/TransitionNode system |

## Key Decisions

(record decisions here as they are made)

## Links

- Target: https://clideo.com/editor/
- Etro: https://github.com/etro-js/etro
- OpenVideo: https://github.com/openvideodev/openvideo
- VideoContext: https://github.com/bbc/VideoContext
- WebCodecs MDN: https://developer.mozilla.org/en-US/docs/Web/API/WebCodecs_API
- WebGL2 Fundamentals: https://webgl2fundamentals.org/
