package skylight

import (
	"os/exec"
	"path/filepath"
	"testing"

	"howett.net/plist"
)

type bridgeFixture struct {
	Windows  []WindowInfo `plist:"windows"`
	Displays []Display    `plist:"displays"`
	Spaces   []uint64     `plist:"spaces"`
	Titles   []struct {
		ID    uint32 `plist:"id"`
		Title string `plist:"title"`
	} `plist:"titles"`
	Empty []string `plist:"empty"`
}

// Exercise the same CoreFoundation producer used by the actual native bridge.
func bridgePayloads(tb testing.TB) (compact, xml []byte) {
	tb.Helper()
	executable := filepath.Join(tb.TempDir(), "plist-bridge")
	if out, err := exec.Command("clang", "-fobjc-arc", "-I.", "-framework", "Foundation", "testdata/plist-bridge.m", "-o", executable).CombinedOutput(); err != nil {
		tb.Fatalf("compile native fixture: %v: %s", err, out)
	}
	var err error
	if compact, err = exec.Command(executable).Output(); err != nil {
		tb.Fatal(err)
	}
	if xml, err = exec.Command(executable, "xml").Output(); err != nil {
		tb.Fatal(err)
	}
	return
}

func TestNativeBridgeCompactPayloadPreservesWindowAndDesktopIdentity(t *testing.T) {
	compact, xml := bridgePayloads(t)
	t.Logf("native payload: %d bytes; XML baseline: %d bytes", len(compact), len(xml))
	// Prevent reintroducing the large text payload seen in idle CPU profiles.
	if len(compact) >= len(xml)/2 {
		t.Errorf("native payload %d bytes; want less than half of XML's %d", len(compact), len(xml))
	}
	for _, data := range [][]byte{compact, xml} {
		var got bridgeFixture
		if _, err := plist.Unmarshal(data, &got); err != nil {
			t.Fatal(err)
		}
		if len(got.Windows) != 200 {
			t.Fatalf("windows: %d", len(got.Windows))
		}
		w := got.Windows[0]
		if w.Number != 200 || w.OwnerPID != 43 || w.OwnerName != "Fixture" || w.Name != "Janela 0 – 文档 🪟" || w.Layer != 0 || w.Alpha != 0.75 || w.Bounds != (WindowBounds{X: -100.25, Y: 12.5, Width: 800, Height: 600}) {
			t.Fatalf("window fields changed: %#v", w)
		}
		if len(got.Displays) != 2 || got.Displays[0].UUID != "display-A" || got.Displays[1].UUID != "display-B" || got.Displays[0].CurrentSpace.ID() != 9007199254740993 || got.Displays[1].CurrentSpace.ID() != 13 || len(got.Displays[0].Spaces) != 2 || len(got.Displays[1].Spaces) != 1 || got.Displays[0].Spaces[0].ID() != 9007199254740993 || got.Displays[0].Spaces[1].ID() != 7 || got.Displays[1].Spaces[0].ID() != 13 {
			t.Fatalf("desktop identity changed: %#v", got.Displays)
		}
		if len(got.Spaces) != 2 || got.Spaces[0] != 9007199254740993 || got.Spaces[1] != 7 {
			t.Fatalf("space membership changed: %v", got.Spaces)
		}
		if len(got.Titles) != 1 || got.Titles[0].ID != 200 || got.Titles[0].Title != "" || len(got.Empty) != 0 {
			t.Fatalf("empty title/list changed")
		}
	}
}

func BenchmarkNativeBridgeDecode(b *testing.B) {
	compact, xml := bridgePayloads(b)
	for name, data := range map[string][]byte{"native": compact, "xml": xml} {
		b.Run(name, func(b *testing.B) {
			b.ReportAllocs()
			for b.Loop() {
				var got bridgeFixture
				if _, err := plist.Unmarshal(data, &got); err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}
