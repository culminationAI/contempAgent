# ContempAgent v0.3 — Auto Memory

## Current State

- **Version**: v0.3 (2026-03-13)
- **Stack**: TypeScript strict + GLSL + React + WebGL2 + WebCodecs + Node.js + Express + FFmpeg
- **Target**: Clideo-like browser video editor (https://clideo.com/editor/)
- **Status**: Agent installed. Run /meditate for codebase onboarding.
- **Agents**: 4 (frontend, backend, pathfinder, qa) — all Opus
- **Skills**: 4 (/review, /debug, /deploy, /meditate)
- **Hooks**: 3 (session-start, memory-inject, post-edit-lint)
- **MCP**: 4 (context7, filesystem, memento, github)

## Architecture

- **Pattern**: Studio (state management) / Compositor (WebGL2 rendering engine)
- **Key insight**: GPU-to-CPU memory copies are the biggest bottleneck — keep data on GPU throughout pipeline
- **Rendering**: WebGL2 required — FBO per track, GLSL shader chain, blend pass compositing
- **Decode**: WebCodecs VideoDecoder for precise frame extraction (not `<video>` element)
- **Export**: WebCodecs VideoEncoder client-side + FFmpeg server-side fallback

## Project Structure

Determined by /meditate scan. Optional scaffold templates in `.claude/scaffold/`.

## Reference Libraries

| Library | Use Case | Notes |
|---------|----------|-------|
| **Etro** | TypeScript + GLSL reference | Cleanest API: layers, effects, `movie.record()` |
| **OpenVideo** | Architecture reference | Studio/Compositor pattern, React + WebCodecs + PixiJS |
| **BBC VideoContext** | WebGL compositing reference | Graph-based, EffectNode/TransitionNode system |

## Key Decisions

- v0.2: Added QA agent, hooks (memory-inject, session-start, post-edit-lint), skills (/review, /debug, /deploy, /meditate), monorepo scaffolding, Docker dev environment

## Links

- Target: https://clideo.com/editor/
- Etro: https://github.com/etro-js/etro
- OpenVideo: https://github.com/openvideodev/openvideo
- VideoContext: https://github.com/bbc/VideoContext
- WebCodecs MDN: https://developer.mozilla.org/en-US/docs/Web/API/WebCodecs_API
- WebGL2 Fundamentals: https://webgl2fundamentals.org/
