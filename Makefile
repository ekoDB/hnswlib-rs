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

.PHONY: all setup build build-release test test-x86 check fmt fmt-md lint lint-fix docs clean deps-check deps-update audit install-hooks versions set-version help

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
