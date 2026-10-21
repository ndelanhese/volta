package main

import (
	"fmt"
	"github.com/cehbz/spacekit/internal/arrangement"
	"github.com/cehbz/spacekit/internal/layout"
	"github.com/cehbz/spacekit/internal/skylight"
	"github.com/cehbz/spacekit/internal/store"
	"time"
)

func rememberArrangement(st *store.Store, spaces []layout.SavedSpace, windows []arrangement.Seen, boot, at time.Time) error {
	arr, err := st.Arrangement(displaySet(spaces))
	if err != nil {
		return err
	}
	if err := st.SetSpaces(arr, spaces); err != nil {
		return err
	}
	recorded, err := st.Recorded(arr, boot)
	if err != nil {
		return err
	}
	byBinding := make(map[uint32]arrangement.Recorded)
	for _, r := range recorded {
		byBinding[r.Binding] = r
	}
	var decisions []arrangement.Decision
	for _, w := range windows {
		r := byBinding[w.Binding]
		if r.Owed {
			decisions = append(decisions, arrangement.Decision{Kind: arrangement.Release, Window: r.Window, Seen: w})
		}
		decisions = append(decisions, arrangement.Decision{Kind: arrangement.Adopt, Window: r.Window, Seen: w})
	}
	return st.Apply(arr, boot, at, "manual remember", decisions)
}

func rememberCmd() error {
	s, err := gather()
	if err != nil {
		return err
	}
	if layout.OverviewOpen(s.all) || skylight.SessionLocked() {
		return fmt.Errorf("close Mission Control and unlock the session before remembering")
	}
	st, err := openStore()
	if err != nil {
		return err
	}
	defer st.Close()
	if err := rememberArrangement(st, s.spaces, seenWindows(s), bootTime(), time.Now()); err != nil {
		return err
	}
	if err := saveCmd("", 200, 10*time.Minute); err != nil {
		return err
	}
	fmt.Printf("remembered %d windows for this display configuration\n", len(seenWindows(s)))
	return nil
}
