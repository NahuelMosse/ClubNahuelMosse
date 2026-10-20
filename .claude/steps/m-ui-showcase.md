# Module ui · Step 9, a showcase is judged in video

Read only if the design line's expression is 8 or more —a showcase—, while `ui` is on in `.claude/kit.json`.
It is part of `steps/m-ui-screen.md`, which links here; the rest of the step is there.

## At a glance

A showcase is judged in video: `node .claude/tools/showreel.mjs <url> --out specs/<card>/showreel` records the tour and its
frame checks (`checks.json`; one failing exits 1 and is fixed first); a blind judge scores 1 to 10 impact, choreography, depth,
detail and each scene against its reference; an interaction pass exercises each signature interaction by script; a message
reader gets only the page's text and the design line's message. It passes at 8 or more in every one and with no reader action.
Gaps are `DA-NN` lines in `specs/<card>/design-actions.md`, closed with the frame that shows them fixed; the verdict is in
`specs/<card>/judge.md`. The second lap follows the same two conditions as `steps/m-ui-screen.md`.

Read the rest only when the first lap scores under 8 or the judge's rubric or the interaction pass has to be set up.

## The video judgment

**It is judged in video**, the way it will be seen:

- `node .claude/tools/showreel.mjs <url> --out specs/<card>/showreel` records the tour —3 s
  still, the whole scroll, the pointer over what can be touched—, a strip of key frames and one
  settled still per section (`scenes.png`, and `scene-N.png` at full size: the judge reads those): each frame waits for what is entering to finish. Before the judge, `checks.json` holds the frame checks —text under 16 px, an empty frame, clipped text, a black canvas, a section shorter than the viewport—; one failing exits 1 and is fixed first;
- a **blind judge** —a subagent with vision that does not know which version is which— looks at
  the strip, the scenes, the video and the design line's references, and scores 1 to 10: impact
  in the first 3 s, choreography, depth and materials, detail, **each scene against the reference
  it copies** (the scene table), and **would you show it in a video?**;
- an **interaction pass**: each signature interaction exercised by script —drag a known
  distance, hover, click— and measured against `reference/showcase.md` (“What is touched is
  tested by touching it”); a drag that does not follow the pointer 1:1 is an action;
- a **message reader**, in parallel —a subagent that gets only the page's text and the three
  lines of the design line's message (`reference/showcase.md`), playing the viewer who does not
  know the project—: for each section, the conclusion it draws, and each figure or name marked
  *understood*, *missing context* or *works against the message*. Any of the last two is an
  action;
- **it passes at 8 or more in every one**, and with no action from the reader. Under that, one lap fixes what the judge named. The judge's second and last lap
  verifies those fixes, before the final `verify.mjs`, within the cap of the time plan —no third lap—, only if some action closes with something that is not a command or the File map names 15 or more production files (`steps/m-ui-screen.md`, “When it runs”);
- **the judge's gaps are written down**: `specs/<card>/design-actions.md`, one line per gap with
  an ID `DA-NN`, closed with the frame that shows it fixed (`DA-03 · closed · scene-4.png`). The
  rubric is **fixed before the first lap and does not change between laps**. The verdict is saved in
  `specs/<card>/judge.md`.

In a showcase, the video goes in the close for whoever approves it.
