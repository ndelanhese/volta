package main

import (
	"bytes"
	"log"
	"strings"
	"testing"
	"time"

	"github.com/cehbz/spacekit/internal/settle"
)

// A look put off again and again while the overview is showing is logged
// once, when it is first put off; the retried look logs itself when it runs.
func TestPutOffLogsOnce(t *testing.T) {
	var buf bytes.Buffer
	out, flags := log.Writer(), log.Flags()
	log.SetOutput(&buf)
	log.SetFlags(0)
	defer func() { log.SetOutput(out); log.SetFlags(flags) }()

	w := &watcher{spaces: settle.New(spaceQuiet)}
	for i := 0; i < 3; i++ {
		w.putOff("interval", "the overview is showing")
	}
	if w.retry != "interval" || !w.spaces.Open() {
		t.Fatalf("retry %q, spaces open %v; want the look queued", w.retry, w.spaces.Open())
	}
	if n := strings.Count(buf.String(), "put off"); n != 1 {
		t.Fatalf("logged %d put-off lines, want 1:\n%s", n, buf.String())
	}
}

// No main-thread work (including a snapshot save) may start during the
// quiet period after a Space notification. The main loop is deliberately
// absent here: attempting to dispatch to it makes this regression fail.
func TestSpaceSwitchHoldsLooksAndSnapshots(t *testing.T) {
	for _, action := range []string{"look", "save"} {
		t.Run(action, func(t *testing.T) {
			w := &watcher{displays: settle.New(displayQuiet), spaces: settle.New(spaceQuiet)}
			w.spaces.Note(time.Now())
			done := make(chan struct{})
			go func() {
				if action == "look" {
					w.look("interval")
				} else {
					w.save("interval")
				}
				close(done)
			}()
			select {
			case <-done:
			case <-time.After(200 * time.Millisecond):
				t.Fatal("started main-thread work while a desktop switch was settling")
			}
		})
	}
}
