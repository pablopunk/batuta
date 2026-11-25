import { useCallback, useEffect, useReducer, useRef, useState } from "react";
import { desktopReducer, type DesktopAction } from "./reducer";
import type { Chapter, Keys, Step } from "./script";
import { initialState, type DesktopState } from "./state";

const PAUSE_BEFORE_LOOP = 1200;

class Cancelled extends Error {}

const actionsOf = (step: Step): DesktopAction[] => (step.action ? [step.action].flat() : []);

const stateAtChapter = (chapters: Chapter[], index: number): DesktopState =>
  chapters
    .slice(0, index)
    .flatMap((chapter) => chapter.steps.flatMap(actionsOf))
    .reduce(desktopReducer, initialState);

/**
 * Plays the chapters in a loop. `jump` restarts from any chapter, with the desktop already in that chapter's state.
 * `pause` stops after the current step; `resume` goes on from the next one.
 */
export function usePlayer(chapters: Chapter[]) {
  const [state, dispatch] = useReducer(desktopReducer, initialState);
  const [chapterIndex, setChapterIndex] = useState(0);
  const [keys, setKeys] = useState<(Keys & { count: number }) | null>(null);
  const [instant, setInstant] = useState(false);
  const [playing, setPlaying] = useState(true);
  const run = useRef(0);
  const keyPresses = useRef(0);
  const nextStep = useRef({ chapter: 0, step: 0 });

  const play = useCallback(
    async (fromChapter: number, fromStep = 0) => {
      const token = ++run.current;
      setPlaying(true);
      const sleep = (ms: number) =>
        new Promise<void>((resolve, reject) =>
          setTimeout(() => (token === run.current ? resolve() : reject(new Cancelled())), ms),
        );
      try {
        for (let index = fromChapter, isFirstChapter = true; ; index = (index + 1) % chapters.length) {
          const loopedBackToStart = index === 0 && !isFirstChapter;
          if (loopedBackToStart) {
            dispatch({ type: "reset" });
            await sleep(PAUSE_BEFORE_LOOP);
          }
          const firstStep = isFirstChapter ? fromStep : 0;
          isFirstChapter = false;
          setChapterIndex(index);
          const steps = chapters[index].steps;
          for (let stepIndex = firstStep; stepIndex < steps.length; stepIndex++) {
            const step = steps[stepIndex];
            if (step.keys !== undefined) setKeys(step.keys && { ...step.keys, count: ++keyPresses.current });
            actionsOf(step).forEach(dispatch);
            nextStep.current = { chapter: index, step: stepIndex + 1 };
            await sleep(step.hold);
          }
        }
      } catch (error) {
        if (!(error instanceof Cancelled)) throw error;
      }
    },
    [chapters],
  );

  const jump = useCallback(
    (index: number) => {
      setInstant(true);
      setKeys(null);
      dispatch({ type: "load", state: stateAtChapter(chapters, index) });
      requestAnimationFrame(() => requestAnimationFrame(() => setInstant(false)));
      void play(index);
    },
    [chapters, play],
  );

  const pause = useCallback(() => {
    run.current++;
    setPlaying(false);
  }, []);

  const resume = useCallback(() => {
    void play(nextStep.current.chapter, nextStep.current.step);
  }, [play]);

  useEffect(() => {
    void play(0);
    return () => {
      run.current++;
    };
  }, [play]);

  return { state, dispatch, chapterIndex, keys, instant, jump, playing, pause, resume };
}
