import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile } from "remotion";
import { linearTiming, TransitionSeries } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;
export const FADE = 15;

// ffprobe durations, rounded to whole frames.
const CLIPS = [
  { src: staticFile("clip-1.mp4"), frames: 779 },
  { src: staticFile("clip-2.mp4"), frames: 971 },
  { src: staticFile("clip-3.mp4"), frames: 228 },
] as const;

export const CUT_DURATION =
  CLIPS.reduce((sum, clip) => sum + clip.frames, 0) - FADE * (CLIPS.length - 1);

const Clip: React.FC<{ src: string }> = ({ src }) => (
  <AbsoluteFill style={{ backgroundColor: "#000" }}>
    <OffthreadVideo
      src={src}
      style={{ width: "100%", height: "100%", objectFit: "contain" }}
    />
  </AbsoluteFill>
);

export const Cut: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: "#000" }}>
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={CLIPS[0].frames}>
        <Clip src={CLIPS[0].src} />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: FADE })}
      />
      <TransitionSeries.Sequence durationInFrames={CLIPS[1].frames}>
        <Clip src={CLIPS[1].src} />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({ durationInFrames: FADE })}
      />
      <TransitionSeries.Sequence durationInFrames={CLIPS[2].frames}>
        <Clip src={CLIPS[2].src} />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  </AbsoluteFill>
);
