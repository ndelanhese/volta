package main

import (
	"github.com/cehbz/spacekit/internal/arrangement"
	"github.com/cehbz/spacekit/internal/layout"
	"testing"
)

func TestSnapshotKeepsTrustedHiddenFramesAndCurrentVisibleEdits(t *testing.T) {
	s := &snapshot{
		spaces: []layout.SavedSpace{{UUID: "hidden", DisplayUUID: "display", Index: 0}, {UUID: "shown", DisplayUUID: "display", Index: 1}},
		windows: []layout.LiveWindow{
			{ID: 1, OwnerName: "Hidden", Frame: layout.Rect{X: 4800, Y: 33, W: 1512, H: 949}},
			{ID: 2, OwnerName: "Shown", Frame: layout.Rect{X: 200, Y: 90, W: 800, H: 600}},
			{ID: 3, OwnerName: "Unknown hidden", Frame: layout.Rect{X: -1648, Y: 33, W: 700, H: 500}},
		},
		winSpace: map[uint32]uint64{1: 10, 2: 20, 3: 10},
		idToKey:  map[uint64]string{10: "hidden", 20: "shown"},
		current:  map[uint64]bool{20: true},
	}
	records := []arrangement.Recorded{
		{Binding: 1, Placed: true, Placement: arrangement.Placement{Space: "hidden", Frame: layout.Rect{X: 0, Y: 33, W: 1512, H: 949}}},
		{Binding: 2, Placed: true, Placement: arrangement.Placement{Space: "shown", Frame: layout.Rect{X: 0, Y: 33, W: 1512, H: 949}}},
	}
	l := buildLayout(s, records)
	if len(l.Windows) != 2 {
		t.Fatalf("saved %d windows; unobserved hidden geometry must not enter boot restoration", len(l.Windows))
	}
	if l.Windows[0].Frame != (layout.Rect{X: 0, Y: 33, W: 1512, H: 949}) {
		t.Fatalf("hidden compositor offset entered snapshot: %+v", l.Windows[0].Frame)
	}
	if l.Windows[1].Frame != (layout.Rect{X: 200, Y: 90, W: 800, H: 600}) {
		t.Fatalf("visible user edit was lost: %+v", l.Windows[1].Frame)
	}
	if s.windows[0].Frame.X != 4800 {
		t.Fatal("snapshot altered live observation")
	}
}
