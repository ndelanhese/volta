package main

import "github.com/cehbz/spacekit/internal/arrangement"

// observe records intent without moving windows. Hidden compositor frames are unreliable.
func observe(recorded []arrangement.Recorded, seen []arrangement.Seen, visible map[string]bool) []arrangement.Decision {
	byBinding := make(map[uint32]arrangement.Recorded, len(recorded))
	for _, r := range recorded {
		byBinding[r.Binding] = r
	}
	var ds []arrangement.Decision
	for _, s := range seen {
		r, known := byBinding[s.Binding]
		if r.Owed {
			ds = append(ds, arrangement.Decision{Kind: arrangement.Release, Window: r.Window, Seen: s})
		}
		if !visible[s.Space] {
			if !known || !r.Placed || r.Space == s.Space {
				continue
			}
			s.Frame = r.Frame
		}
		if !known || !r.Placed || !r.Placement.InPlace(s.Placement) {
			ds = append(ds, arrangement.Decision{Kind: arrangement.Adopt, Window: r.Window, Seen: s})
		}
	}
	return ds
}
