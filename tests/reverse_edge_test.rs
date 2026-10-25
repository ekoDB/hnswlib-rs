//! Regression test for reverse-edge placement during insertion.
//!
//! When a point is inserted, each of its neighbours gets a reverse edge back to
//! it. That edge must go into the neighbour's list for the layer being linked.
//! If it goes into the list for the new point's own level instead, a level-0
//! neighbour of a point inserted above level 0 never receives the edge in its
//! layer-0 list, so a layer-0 search that pivots to that neighbour cannot reach
//! the new point: a two-point index searched for two results returns one.
//!
//! Levels are sampled randomly at insertion and cannot be chosen through the
//! public API, so the test builds many independent two-point indexes, reads back
//! the level each point landed on, and checks the case that matters (first point
//! at level 0, second point above it) directly. It keeps building until that
//! case has been seen `MIN_TARGET_CASES` times, and fails if it never is, so it
//! cannot pass without exercising the case.
//!
//! Run with: cargo test --test reverse_edge_test -- --nocapture

use anndists::dist::*;
use hnsw_rs::prelude::*;

const NEAR: usize = 0;
const FAR: usize = 1;

const MAX_NB_CONNECTION: usize = 16;
const MAX_LAYER: usize = 16;
const EF_CONSTRUCTION: usize = 200;
const EF_SEARCH: usize = 16;

/// Builds with near at level 0 and far above it that must be observed.
/// With 16 connections the case occurs in about 6% of builds, so this needs a
/// few hundred builds on average.
const MIN_TARGET_CASES: usize = 20;
/// Upper bound on builds, far above what `MIN_TARGET_CASES` needs on average.
const MAX_BUILDS: usize = 20_000;

/// Returns the sampled level of the point with `origin_id`, and the origin ids
/// of its layer-0 neighbours.
fn level_and_layer0_neighbours(hnsw: &Hnsw<f32, DistL2>, origin_id: usize) -> (u8, Vec<usize>) {
    let point = hnsw
        .get_point_indexation()
        .into_iter()
        .find(|p| p.get_origin_id() == origin_id)
        .unwrap_or_else(|| panic!("point {origin_id} missing from the index"));
    let layer0 = point.get_neighborhood_id()[0]
        .iter()
        .map(|n| n.get_origin_id())
        .collect();
    (point.get_point_id().0, layer0)
}

#[test]
fn test_two_point_index_returns_both_points() {
    let near = vec![0.0_f32, 0.0];
    let far = vec![10.0_f32, 0.0];
    let query = vec![0.1_f32, 0.0];

    let mut builds = 0;
    let mut target_cases = 0;
    while target_cases < MIN_TARGET_CASES && builds < MAX_BUILDS {
        builds += 1;
        let hnsw =
            Hnsw::<f32, DistL2>::new(MAX_NB_CONNECTION, 2, MAX_LAYER, EF_CONSTRUCTION, DistL2);
        hnsw.insert((&near, NEAR));
        hnsw.insert((&far, FAR));

        let (near_level, near_layer0) = level_and_layer0_neighbours(&hnsw, NEAR);
        let (far_level, _) = level_and_layer0_neighbours(&hnsw, FAR);

        if near_level == 0 && far_level > 0 {
            target_cases += 1;
            assert!(
                near_layer0.contains(&FAR),
                "build {builds}: near is at level 0 and far at level {far_level}, \
                 but near's layer-0 neighbours {near_layer0:?} do not include far"
            );
        }

        let mut found: Vec<usize> = hnsw
            .search(&query, 2, EF_SEARCH)
            .iter()
            .map(|n| n.d_id)
            .collect();
        found.sort_unstable();
        assert_eq!(
            found,
            vec![NEAR, FAR],
            "build {builds}: search for 2 in a two-point index returned {found:?} \
             (near at level {near_level}, far at level {far_level})"
        );
    }

    assert!(
        target_cases >= MIN_TARGET_CASES,
        "only {target_cases} of {builds} builds placed near at level 0 and far above it; \
         the case under test was not exercised enough"
    );
    println!("{builds} builds, {target_cases} with near at level 0 and far above it");
}
