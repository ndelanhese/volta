package main

import (
	"github.com/cehbz/spacekit/internal/arrangement"
	"github.com/cehbz/spacekit/internal/layout"
	"testing"
	"time"
)

func TestObserveLearnsMovesWithoutRepairing(t *testing.T) {
	old := arrangement.Recorded{Window: 1, Binding: 2, Placed: true, Owed: true, Placement: arrangement.Placement{Space: "a", Frame: layout.Rect{X: 10, W: 100, H: 100}}}
	seen := arrangement.Seen{Binding: 2, Placement: arrangement.Placement{Space: "b", Frame: layout.Rect{X: 5000, W: 100, H: 100}}}
	ds := observe([]arrangement.Recorded{old}, []arrangement.Seen{seen}, map[string]bool{})
	if len(ds) != 2 || ds[0].Kind != arrangement.Release || ds[1].Kind != arrangement.Adopt || ds[1].Seen.Space != "b" || ds[1].Seen.Frame.X != 10 {
		t.Fatalf("unexpected decisions: %+v", ds)
	}
}

func TestObserveLearnsVisibleFramesAndIgnoresHiddenDrift(t *testing.T) {
	old := arrangement.Recorded{Window: 1, Binding: 2, Placed: true, Placement: arrangement.Placement{Space: "a", Frame: layout.Rect{X: 10, W: 100, H: 100}}}
	seen := arrangement.Seen{Binding: 2, Placement: arrangement.Placement{Space: "a", Frame: layout.Rect{X: 500, W: 100, H: 100}}}
	if ds := observe([]arrangement.Recorded{old}, []arrangement.Seen{seen}, nil); len(ds) != 0 {
		t.Fatalf("hidden drift: %+v", ds)
	}
	if ds := observe([]arrangement.Recorded{old}, []arrangement.Seen{seen}, map[string]bool{"a": true}); len(ds) != 1 || ds[0].Kind != arrangement.Adopt || ds[0].Seen.Frame.X != 500 {
		t.Fatalf("visible move: %+v", ds)
	}
}

func TestRestoreRequiresRecentHotplugAndChangedDisplaySet(t *testing.T) {
	now := time.Unix(100, 0)
	for _, tc := range []struct {
		pending       bool
		deadline      time.Time
		before, after string
		want          bool
	}{
		{true, now.Add(time.Second), "a", "a,b", true},
		{false, now.Add(time.Second), "a", "a,b", false},
		{true, now.Add(time.Second), "a", "a", false},
		{true, now.Add(-time.Second), "a", "a,b", false},
		{true, now.Add(time.Second), "", "a", false},
		{true, now.Add(time.Second), "a", "", false},
	} {
		if got := shouldRestore(tc.pending, tc.deadline, now, tc.before, tc.after); got != tc.want {
			t.Fatalf("%+v: got %v", tc, got)
		}
	}
}
