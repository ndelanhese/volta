package main

import (
	"path/filepath"
	"testing"
	"time"

	"github.com/cehbz/spacekit/internal/arrangement"
	"github.com/cehbz/spacekit/internal/layout"
	"github.com/cehbz/spacekit/internal/store"
)

func TestVoltaDataDirectoryIsIsolated(t *testing.T) {
	want := filepath.Join(t.TempDir(), "Volta data")
	t.Setenv("SPACEKEEPER_DATA_DIR", want)
	if got := dataDir(); got != want {
		t.Fatalf("dataDir = %q, want %q", got, want)
	}
}

func TestRememberExplicitlyAdoptsHiddenWindowsAndClearsOwed(t *testing.T) {
	st, err := store.Open(filepath.Join(t.TempDir(), "test.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer st.Close()
	boot, now := time.Unix(100, 0), time.Unix(200, 0)
	spaces := []layout.SavedSpace{{UUID: "hidden", DisplayUUID: "monitor", Index: 0}}
	windows := []arrangement.Seen{{Binding: 42, Bundle: "test.app", App: "Test", Placement: arrangement.Placement{
		Space: "hidden", Frame: layout.Rect{X: 10, Y: 20, W: 300, H: 400},
	}}}
	if err := rememberArrangement(st, spaces, windows, boot, now); err != nil {
		t.Fatal(err)
	}
	arr, _ := st.Arrangement("monitor")
	recorded, _ := st.Recorded(arr, boot)
	if len(recorded) != 1 {
		t.Fatalf("remembered %d windows, want 1", len(recorded))
	}
	identity := recorded[0].Window
	if _, err := st.OweAll(arr, boot, now, "test", []uint32{42}); err != nil {
		t.Fatal(err)
	}
	windows[0].Frame.X = 900
	if err := rememberArrangement(st, spaces, windows, boot, now.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	recorded, _ = st.Recorded(arr, boot)
	if len(recorded) != 1 || recorded[0].Window != identity || recorded[0].Frame.X != 900 || recorded[0].Owed {
		t.Fatalf("manual intent not preserved: %+v", recorded)
	}
	other, _ := st.Arrangement("laptop")
	if got, _ := st.Recorded(other, boot); len(got) > 0 && got[0].Placed {
		t.Fatal("modified another display arrangement")
	}
}
