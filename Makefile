# Makefile for hnsw_rs (ekoDB fork of hnswlib-rs)

CARGO := cargo

# Color codes for pretty output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BOLD := \033[1m
RESET := \033[0m

# ASCII Banner
BANNER := "$(BOLD) ██████═╗ ██╗  ██╗  ██████╗  ████████╗ ████████╗$(RESET)\n$(BOLD)██╔═══██╝ ██║ ██╔╝ ██╔═══██╗  ██╔═══██║ ██╔═══██╗$(RESET)\n$(BOLD)████████╗ █████╔╝  ██║   ██║  ██║   ██║████████╔╝$(RESET)\n$(BOLD)██╔═════╝ ██╔═██╗  ██║   ██║  ██║   ██║ ██╔═══██╗$(RESET)\n$(BOLD)████████╗ ██║  ██╗ ╚██████╔╝ ████████║ ████████╔╝$(RESET)\n$(BOLD)╚═══════╝ ╚═╝  ╚═╝  ╚═════╝  ╚═══════╝ ╚═══════╝$(RESET)"

SUBTITLE := \
	"          🕸️   hnsw_rs  •  Vector Search (ekoDB fork)" "\n"

.PHONY: all setup build build-release test test-x86 check fmt fmt-md lint lint-fix docs clean deps-check deps-update audit install-hooks versions set-version bump-version help

all: build

help:
	@echo ""
	@echo $(BANNER)
	@echo ""
	@echo $(SUBTITLE)
	@echo ""
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "📌 $(CYAN)BUILD & TEST$(RESET)"
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "  🧰 $(GREEN)make setup$(RESET)              - One-time dev setup (rustup target, HDF5, cargo tools, git hooks)"
	@echo "  🛠️  $(GREEN)make build$(RESET)              - Debug build"
	@echo "  🚀 $(GREEN)make build-release$(RESET)      - Release build"
	@echo "  🧪 $(GREEN)make test$(RESET)               - Tests (matches CI; examples need system HDF5)"
	@echo "  💻 $(GREEN)make test-x86$(RESET)           - Run lib + integration tests under Rosetta (Apple Silicon)"
	@echo "  ✅ $(GREEN)make check$(RESET)              - Check compilation without building"
	@echo ""
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "🔧 $(CYAN)CODE QUALITY$(RESET)"
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "  🖌️  $(GREEN)make fmt$(RESET)                - Format all code (Rust + Markdown)"
	@echo "  📝 $(GREEN)make fmt-md$(RESET)             - Format Markdown files only"
	@echo "  🔍 $(GREEN)make lint$(RESET)               - fmt --check + clippy -D warnings (matches CI)"
	@echo "  🔧 $(GREEN)make lint-fix$(RESET)           - Run clippy with auto-fix"
	@echo "  📚 $(GREEN)make docs$(RESET)               - Build crate documentation"
	@echo "  🧹 $(GREEN)make clean$(RESET)              - Remove build artifacts"
	@echo ""
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "📦 $(CYAN)DEPENDENCIES$(RESET)"
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "  📋 $(GREEN)make deps-check$(RESET)         - Check for outdated dependencies"
	@echo "  📦 $(GREEN)make deps-update$(RESET)        - Upgrade dependencies (bumps Cargo.toml)"
	@echo "  🔒 $(GREEN)make audit$(RESET)              - Audit dependencies for vulnerabilities"
	@echo "  🪝 $(GREEN)make install-hooks$(RESET)      - Install the pre-commit git hook (lint + test)"
	@echo ""
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "🔢 $(CYAN)VERSIONING$(RESET)"
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"
	@echo "  📋 $(GREEN)make versions$(RESET)           - Show crate version"
	@echo "  🔢 $(GREEN)make set-version VERSION=x.y.z$(RESET) - Set crate version + refresh Cargo.lock"
	@echo "  🚀 $(GREEN)make bump-version [VERSION=x.y.z]$(RESET) - Cap a release: collapse CHANGELOG.md's [Unreleased], set-version, print the commit subject (default: next patch; never commits)"

# One-time developer setup: everything the other targets rely on. Idempotent.
setup:
	@echo "🧰 $(CYAN)Setting up the development environment...$(RESET)"
	@if [ "$$(uname -s)" = "Darwin" ]; then \
		echo "$(CYAN)Adding x86_64-apple-darwin target (for make test-x86)...$(RESET)"; \
		rustup target add x86_64-apple-darwin; \
		if ! brew list hdf5 >/dev/null 2>&1; then \
			echo "$(CYAN)Installing HDF5 (hdf5 dev-dependency for the examples)...$(RESET)"; \
			brew install hdf5; \
		fi; \
	else \
		if ! dpkg -s libhdf5-dev >/dev/null 2>&1; then \
			echo "$(YELLOW)Install HDF5 for the examples: sudo apt-get install -y libhdf5-dev$(RESET)"; \
		fi; \
	fi
	@if ! command -v cargo-audit >/dev/null 2>&1; then \
		echo "$(CYAN)Installing cargo-audit...$(RESET)"; \
		cargo install cargo-audit; \
	fi
	@if ! command -v cargo-upgrade >/dev/null 2>&1; then \
		echo "$(CYAN)Installing cargo-edit (provides cargo upgrade)...$(RESET)"; \
		cargo install cargo-edit; \
	fi
	@$(MAKE) install-hooks
	@echo "✅ $(GREEN)Setup complete!$(RESET)"

build:
	$(CARGO) build

build-release:
	$(CARGO) build --release

# Matches .github/workflows/rust.yml exactly: green here means green in CI.
# cargo test also compiles the examples, whose hdf5 dev-dependency links the
# system HDF5 library (brew install hdf5 / apt-get install libhdf5-dev).
test:
	$(CARGO) test --locked

# Lib + integration tests under Rosetta on Apple Silicon (examples are skipped:
# Homebrew HDF5 is arm64-only, so the x86 example binaries cannot link).
# NOTE: Rosetta has no AVX2, so distance evaluation takes the scalar fallback;
# real AVX2 SIMD coverage comes from CI on x86_64 hardware.
# Requires the target: rustup target add x86_64-apple-darwin
test-x86:
	@if [ "$$(uname -s)" != "Darwin" ]; then \
		echo "$(YELLOW)test-x86 targets Rosetta on macOS; on an x86_64 host plain 'make test' already covers this.$(RESET)"; \
		exit 1; \
	fi
	$(CARGO) test --locked --target x86_64-apple-darwin --lib --tests

check:
	$(CARGO) check --all-targets

fmt: fmt-md
	$(CARGO) fmt

fmt-md:
	@echo "$(CYAN)Formatting Markdown...$(RESET)"
	@if command -v prettier > /dev/null; then \
		prettier --write *.md 2>/dev/null || true; \
	else \
		echo "$(YELLOW)prettier not installed - skipping Markdown formatting$(RESET)"; \
	fi

# Matches .github/workflows/rust.yml exactly: green here means green in CI.
lint:
	$(CARGO) fmt --check
	$(CARGO) clippy --locked --all-targets -- -D warnings

lint-fix: fmt
	$(CARGO) clippy --locked --all-targets --fix --allow-dirty --allow-staged -- -D warnings

docs:
	$(CARGO) doc --no-deps

clean:
	$(CARGO) clean

deps-check:
	@echo "$(CYAN)Checking for outdated dependencies...$(RESET)"
	@if command -v cargo-outdated >/dev/null 2>&1; then \
		$(CARGO) outdated -R; \
	else \
		echo "$(YELLOW)cargo-outdated not installed.$(RESET)"; \
		echo "$(YELLOW)Run 'cargo install cargo-outdated' to install it.$(RESET)"; \
	fi

deps-update:
	@if ! command -v cargo-upgrade >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing cargo-edit (provides cargo upgrade)...$(RESET)"; \
		cargo install cargo-edit; \
	fi
	@echo "📦 $(CYAN)Upgrading dependencies...$(RESET)"
	cargo upgrade
	$(CARGO) update

audit:
	@echo "$(CYAN)Auditing dependencies for vulnerabilities...$(RESET)"
	@if command -v cargo-audit >/dev/null 2>&1; then \
		$(CARGO) audit; \
	else \
		echo "$(YELLOW)cargo-audit not installed.$(RESET)"; \
		echo "$(YELLOW)Run 'cargo install cargo-audit' to install it.$(RESET)"; \
	fi

install-hooks:
	@echo "🪝 $(CYAN)Installing Git hooks...$(RESET)"
	@if [ -f scripts/pre-commit ]; then \
		cp scripts/pre-commit .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "✅ $(GREEN)Git hooks installed!$(RESET)"; \
	else \
		echo "$(YELLOW)scripts/pre-commit not found, skipping...$(RESET)"; \
	fi

versions:
	@grep '^version =' Cargo.toml | head -1

# Usage: make set-version VERSION=0.4.1
# Remember to convert the CHANGELOG [Unreleased] block to a dated version
# block in the same commit, and tag vX.Y.Z on master after merge.
set-version:
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)Error: VERSION is required. Usage: make set-version VERSION=0.4.1$(RESET)"; \
		exit 1; \
	fi
	@# Semver-strict validation so a VERSION value can't smuggle quotes or
	@# whitespace into the awk replacement below.
	@if ! echo "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$$'; then \
		echo "$(RED)Error: VERSION must be semver (x.y.z[-prerelease][+build]). Got: $(VERSION)$(RESET)"; \
		exit 1; \
	fi
	@echo "$(CYAN)Setting Cargo.toml to $(VERSION)...$(RESET)"
	@awk -v version='$(VERSION)' 'BEGIN{done=0} /^version = "[^"]+"$$/ && !done {print "version = \"" version "\""; done=1; next} {print}' Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml
	@echo "$(CYAN)Refreshing Cargo.lock...$(RESET)"
	@$(CARGO) update -p hnsw_rs --precise $(VERSION) 2>/dev/null || $(CARGO) check --quiet
	@echo "$(GREEN)Version set:$(RESET)"
	@grep '^version =' Cargo.toml | head -1

# Usage: make bump-version [VERSION=0.6.0]
#
# Caps a release: collapses CHANGELOG.md's [Unreleased] section into a dated
# version heading, bumps Cargo.toml (reusing set-version) to match, and prints
# the suggested commit subject. Defaults to the next patch version when
# VERSION is omitted. Never commits, tags, or pushes — review the diff
# (git diff) and do that by hand.
#
# No pre-release (-rc.N) ladder on purpose: this crate is a vendored
# dependency consumed by the server via a pinned git revision, never
# published to a package registry, so there is no "burned version" an
# in-progress PR could cost by using a plain X.Y.Z early. Every bump is a
# plain X.Y.Z, same as set-version above already requires.
bump-version:
	@cur="$$(grep '^version = "' Cargo.toml | head -1 | cut -d'"' -f2)"; \
	version="$(VERSION)"; \
	if [ -z "$$version" ]; then \
		major="$$(echo "$$cur" | cut -d. -f1)"; \
		minor="$$(echo "$$cur" | cut -d. -f2)"; \
		patch="$$(echo "$$cur" | cut -d. -f3)"; \
		version="$$major.$$minor.$$((patch + 1))"; \
		echo "$(CYAN)No VERSION given — defaulting to next patch: $$version$(RESET)"; \
	fi; \
	if ! echo "$$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "$(RED)Error: VERSION must be a plain X.Y.Z — this repo has no pre-release ladder. Got: $$version$(RESET)"; \
		exit 1; \
	fi; \
	top="$$(printf '%s\n%s\n' "$$cur" "$$version" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"; \
	if [ "$$top" != "$$version" ] || [ "$$version" = "$$cur" ]; then \
		echo "$(RED)Error: $$version is not above the current $$cur.$(RESET)"; \
		exit 1; \
	fi; \
	unrel_line="$$(grep -nE '^## \[Unreleased\]' CHANGELOG.md | head -1 | cut -d: -f1)"; \
	if [ -z "$$unrel_line" ]; then \
		echo "$(RED)Error: no '## [Unreleased]' heading in CHANGELOG.md.$(RESET)"; \
		exit 1; \
	fi; \
	entries="$$(awk -v start="$$unrel_line" 'NR > start { if ($$0 ~ /^## \[/) exit; if ($$0 ~ /[^[:space:]]/ && $$0 !~ /^#+[[:space:]]/ && $$0 !~ /^[[:space:]]*<!--.*-->[[:space:]]*$$/) print }' CHANGELOG.md | wc -l | tr -d ' ')"; \
	if [ "$$entries" -eq 0 ]; then \
		echo "$(RED)Error: [Unreleased] is empty — nothing to release.$(RESET)"; \
		exit 1; \
	fi; \
	today="$$(date -u +%Y-%m-%d)"; \
	awk -v ln="$$unrel_line" -v ver="$$version" -v d="$$today" \
		'NR == ln { print "## [Unreleased]"; print ""; print "## [" ver "] - " d; next } { print }' \
		CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md; \
	echo "$(GREEN)CHANGELOG: [Unreleased] -> [$$version] - $$today$(RESET)"; \
	$(MAKE) set-version VERSION=$$version; \
	echo ""; \
	echo "$(YELLOW)Review the diff (git diff), then commit ONLY Cargo.toml, Cargo.lock, and CHANGELOG.md.$(RESET)"; \
	echo "$(YELLOW)Suggested commit subject:$(RESET)"; \
	echo "    chore(*): v$$version"
