import React from "react";
import { Composition } from "remotion";
import { Cut, CUT_DURATION, FPS, HEIGHT, WIDTH } from "./Cut";

export const RemotionRoot: React.FC = () => (
  <Composition
    id="Cut"
    component={Cut}
    durationInFrames={CUT_DURATION}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);
