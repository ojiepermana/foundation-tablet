# ENTERPRISE NATIVE TABLET MONOREPO FOUNDATION

## 1. Role & Mission

You are a Principal Software Architect, Senior Rust Engineer, Senior iPadOS Engineer, Senior Android Engineer, Tablet UX Architect, Design System Architect, DevOps Engineer, and Software Quality Engineer.

Your mission is to analyze, design, scaffold, implement, and validate a long-term maintainable, enterprise-oriented native tablet application monorepo.

The project must establish a production-quality architectural foundation for two genuinely native tablet applications sharing one authoritative Rust Core.

### Target Platforms

1. Apple iPadOS — Native SwiftUI application.
2. Android Tablet — Native Jetpack Compose application.

This project targets tablet productivity experiences.

Do not develop the applications as smartphone interfaces merely stretched to fill a tablet screen.

Do not introduce cross-platform UI frameworks.

### Technology Stack

- **Shared Core:** Rust, Cargo Workspace.
- **Interoperability:** UniFFI.
- **iPadOS:** Swift, SwiftUI, Xcode.
- **Android Tablet:** Kotlin, Jetpack Compose, Material 3, Gradle.
- **Adaptive UI:** Native adaptive layout APIs.
- **Shared Design System:** Platform-neutral design tokens.
- **Shared Resources:** Configuration, localization, and brand assets.
- **Automation:** GitHub Actions.
- **Documentation:** Markdown and Architecture Decision Records.
- **Agent Governance:** AGENTS.md and enforceable architectural rules.

Use compatible stable versions of all technologies.

Verify compatibility through official documentation before selecting and pinning versions.

Do not blindly select a library version solely because it is the newest.

### Primary Objective

**One shared Rust application foundation, one shared design language, two genuinely native tablet applications, native adaptive presentation, explicit ownership boundaries, and no duplicated authoritative implementations.**

This is a **foundation-only implementation**.

Do not implement business-specific features, authentication, databases, REST API clients, offline synchronization, image processing, or unrelated application services.

Future functionality will be introduced through separate architectural analysis, PRDs, and implementation plans.

The initial deliverable must be a minimal, functional native tablet monorepo demonstrating:

- Shared Rust interoperability.
- Native iPadOS and Android Tablet applications.
- Tablet-first adaptive layouts.
- Native sidebar and content navigation.
- Basic tablet window and orientation adaptation.
- Shared visual definitions.
- Basic native input behavior.
- Reproducible build integration.
- Automated validation.
- Architecture governance.

Prefer a minimal working foundation over a large incomplete scaffold.

---

## 2. Permanent Architectural Principles

These principles are mandatory and must remain consistent throughout future development.

### 2.1 Single Source of Truth

Each shared responsibility must have one authoritative owner.

| Responsibility | Authoritative Owner |
|---|---|
| Shared application behavior | Rust Core |
| Domain and business rules | Rust Core |
| Business validation | Rust Core |
| Cross-language application DTOs | Rust + UniFFI |
| iPadOS presentation | Swift + SwiftUI |
| Android Tablet presentation | Kotlin + Compose |
| Apple-specific APIs | Swift |
| Android-specific APIs | Kotlin |
| Tablet adaptive layout | Native platform UI |
| Window and scene lifecycle | Native platform UI |
| Platform-specific navigation | Native platform UI |
| Keyboard and pointer interactions | Native platform UI |
| Shared visual definitions | Design System |
| Shared configuration definitions | Shared Resources |
| Shared localization content | Shared Resources |
| Shared brand assets | Shared Resources |
| Code generation | Shared Tooling |
| Architecture policies | docs/ |
| Agent instructions | AGENTS.md |

Do not duplicate authoritative business rules, shared contracts, or canonical design definitions across platforms.

Native UI implementations may differ when required by platform conventions, accessibility, input behavior, or operating-system integration.

### 2.2 Folder Structure Defines Architecture

Repository folders, crates, modules, and applications must clearly define:

- Ownership and responsibility.
- Public interfaces.
- Private implementation boundaries.
- Permitted dependency directions.
- Testing responsibilities.
- Extension policies.
- Generated-code ownership.

Avoid circular dependencies, overlapping responsibilities, and undocumented cross-layer access.

### 2.3 Contract-First Development

Communication between native applications and Rust must use explicit UniFFI contracts.

Do not expose internal Rust implementation types, private data structures, or infrastructure-specific details.

Generated bindings must never be manually modified.

### 2.4 Shared Intent, Native Implementation

Both tablet applications must share the same application behavior and design identity.

However, they must retain genuinely native interactions.

iPadOS must follow Apple Human Interface Guidelines.

Android Tablet must follow Android Adaptive Apps and Material Design guidelines.

Do not force identical navigation controls, animations, window behavior, or rendering.

### 2.5 Tablet-First Architecture

Design for large-screen productivity from the beginning.

Support:

- Portrait and landscape orientations.
- Adaptive navigation.
- Sidebar layouts.
- List-detail layouts.
- Multi-pane content where appropriate.
- Window resizing.
- Multitasking.
- Touch input.
- Hardware keyboard input.
- Mouse and trackpad interaction.
- Accessibility.
- Platform-specific stylus interaction where appropriate.

Do not assume a tablet application always occupies the entire physical display.

### 2.6 Minimalism and Future Extensibility

Implement only what is necessary for a working foundation.

Do not create speculative business services, unnecessary crates, unused frameworks, or placeholder implementations.

Future features must extend established architecture without requiring unnecessary redesign.

---

## 3. Architectural Boundaries

### Layer A — Native Tablet Presentation

**iPadOS responsibilities:**

- SwiftUI views.
- Adaptive navigation.
- Sidebar presentation.
- Content and detail panes.
- Native ViewModels.
- Presentation state.
- Animations.
- Accessibility.
- Keyboard shortcuts.
- Pointer interactions.
- Window-aware layouts.
- iPadOS scene presentation.

**Android Tablet responsibilities:**

- Jetpack Compose UI.
- Material 3 adaptive layouts.
- Navigation rail or drawer as appropriate.
- List-detail presentation.
- Native ViewModels.
- Presentation state.
- Window size class handling.
- Animations.
- Accessibility.
- Keyboard and pointer interactions.
- Window resizing behavior.
- Activity lifecycle handling.

Neither platform may independently implement shared domain rules or shared application algorithms.

### Layer B — Native Platform Integration

Swift owns Apple-specific APIs.

Kotlin owns Android-specific APIs.

Potential future capabilities include:

- Camera.
- File picker.
- Secure storage.
- Biometrics.
- Notifications.
- Stylus capabilities.
- Drag and drop.
- Clipboard.
- Background scheduling.
- Hardware integration.
- Device permissions.
- Window management.
- External displays.

Native capability adapters must communicate through explicit contracts when Rust requires platform services.

These future integrations must not be implemented merely to populate the initial scaffold.

### Layer C — Shared Rust Core

Rust owns future shared behavior such as:

- Domain entities.
- Business rules.
- Application use cases.
- Business validation.
- Shared application state rules.
- Typed errors.
- API orchestration.
- Persistence orchestration.
- Synchronization algorithms.
- Data transformation algorithms.

These are architectural ownership definitions, not instructions to implement those features now.

Rust must remain independent of SwiftUI, UIKit, Compose, Android UI frameworks, and native window rendering.

### Layer D — Shared Design System

The Design System owns canonical visual definitions.

It must remain independent of business logic and Rust runtime behavior.

### Layer E — Shared Resources and Tooling

Shared Resources own platform-neutral source definitions.

Shared Tooling owns deterministic generation, validation, and compliance checks.

---

## 4. Architecture Overview

Establish this logical architecture:

    ENTERPRISE TABLET MONOREPO
    |
    +-- iPadOS Application
    |   |
    |   +-- SwiftUI Adaptive Shell
    |   +-- Native Navigation
    |   +-- Swift ViewModels
    |   +-- Swift UniFFI Bindings
    |
    +-- Android Tablet Application
    |   |
    |   +-- Compose Adaptive Shell
    |   +-- Native Navigation
    |   +-- Kotlin ViewModels
    |   +-- Kotlin UniFFI Bindings
    |
    +-- Shared Rust Core
    |   |
    |   +-- Core Application Logic
    |   +-- Shared Contracts
    |   +-- UniFFI Export Boundary
    |
    +-- Shared Design System
    |   |
    |   +-- Canonical Tokens
    |   +-- Token Generation
    |   +-- Native Theme Mapping
    |
    +-- Shared Resources
    |   |
    |   +-- Configuration
    |   +-- Localization
    |   +-- Brand Assets
    |
    +-- Shared Tooling
    |   |
    |   +-- Bindings Generation
    |   +-- Token Generation
    |   +-- Validation
    |
    +-- Architecture Governance
        |
        +-- AGENTS.md
        +-- docs/
        +-- Automated Compliance
        +-- GitHub Actions

The architecture must distinguish three independent concerns:

1. Shared application behavior.
2. Native tablet presentation.
3. Canonical design and resource definitions.

Do not move adaptive UI or window management responsibilities into Rust.

---

## 5. Repository Structure

Establish the following initial repository baseline:

    tablet-monorepo/
    |
    +-- apps/
    |   |
    |   +-- ipados/
    |   |   +-- App/
    |   |   +-- Presentation/
    |   |   |   +-- Shell/
    |   |   |   +-- Navigation/
    |   |   |   +-- Screens/
    |   |   |   +-- ViewModels/
    |   |   +-- DesignSystem/
    |   |   +-- Platform/
    |   |   +-- Resources/
    |   |   +-- Tests/
    |   |
    |   +-- android-tablet/
    |       +-- app/
    |       +-- presentation/
    |       |   +-- shell/
    |       |   +-- navigation/
    |       |   +-- screens/
    |       |   +-- viewmodel/
    |       +-- designsystem/
    |       +-- platform/
    |       +-- tests/
    |
    +-- crates/
    |   +-- core/
    |   +-- tablet-ffi/
    |
    +-- design-system/
    |   +-- tokens/
    |   |   +-- colors.json
    |   |   +-- typography.json
    |   |   +-- spacing.json
    |   |   +-- radius.json
    |   |   +-- motion.json
    |   |   +-- density.json
    |   +-- schemas/
    |   +-- README.md
    |
    +-- shared/
    |   +-- config/
    |   +-- localization/
    |   +-- assets/
    |   +-- specifications/
    |
    +-- tooling/
    |   +-- codegen/
    |   +-- validation/
    |
    +-- bindings/
    |   +-- swift/
    |   +-- kotlin/
    |
    +-- tests/
    |   +-- fixtures/
    |   +-- contracts/
    |
    +-- scripts/
    |   +-- generate-bindings.sh
    |   +-- generate-design-tokens.sh
    |   +-- build-ipados.sh
    |   +-- build-android-tablet.sh
    |   +-- validate-architecture.sh
    |   +-- test.sh
    |
    +-- docs/
    |   |
    |   +-- architecture/
    |   |   +-- overview.md
    |   |   +-- boundaries.md
    |   |   +-- repository-structure.md
    |   |   +-- dependency-rules.md
    |   |   +-- ownership-matrix.md
    |   |
    |   +-- rules/
    |   |   +-- development-rules.md
    |   |   +-- service-rules.md
    |   |   +-- rust-rules.md
    |   |   +-- ipados-rules.md
    |   |   +-- android-tablet-rules.md
    |   |   +-- design-system-rules.md
    |   |   +-- anti-duplication.md
    |   |
    |   +-- tablet/
    |   |   +-- adaptive-layout.md
    |   |   +-- navigation.md
    |   |   +-- window-management.md
    |   |   +-- input-interactions.md
    |   |   +-- accessibility.md
    |   |   +-- testing-matrix.md
    |   |
    |   +-- design-system/
    |   |   +-- principles.md
    |   |   +-- token-conventions.md
    |   |   +-- platform-mapping.md
    |   |   +-- component-guidelines.md
    |   |
    |   +-- contracts/
    |   |   +-- ffi-conventions.md
    |   |
    |   +-- quality/
    |   |   +-- architecture-compliance.md
    |   |
    |   +-- decisions/
    |   |   +-- ADR-0001-foundation.md
    |   |
    |   +-- plans/
    |       +-- README.md
    |
    +-- .github/
    |   +-- workflows/
    |
    +-- AGENTS.md
    +-- Cargo.toml
    +-- rust-toolchain.toml
    +-- README.md

This is an architectural baseline, not a requirement to create every directory unconditionally.

Only create implemented directories with meaningful responsibilities.

Do not generate unnecessary placeholder files.

Native project layouts may follow their respective platform build-system conventions.

Document any meaningful deviations from this baseline.

---

## 6. Shared Rust Core and UniFFI

Create a minimal Rust Cargo Workspace.

Separate shared Rust implementation from its UniFFI export boundary.

Implement exactly one minimal shared function:

    pub fn hello(name: String) -> String {
        format!("Hello, {name}!")
    }

Expose this function through UniFFI.

Both native tablet applications must invoke the same Rust implementation.

Expected flow:

**iPadOS:**

SwiftUI → Swift Binding → UniFFI → Rust Core

**Android Tablet:**

Compose → Kotlin Binding → UniFFI → Rust Core

The applications must display the result returned by Rust.

Do not independently reproduce the greeting logic in Swift or Kotlin.

Use the example to verify:

- Rust compilation.
- UniFFI generation.
- Swift interoperability.
- Kotlin interoperability.
- Native library linking.
- Data exchange.
- Build integration.
- Basic unit and integration tests.

Ensure the shared Rust Core contains no UI framework dependencies.

Do not introduce databases, networking, or runtime frameworks for this demonstration.

---

## 7. Tablet Adaptive Layout Architecture

**This section is mandatory and must not be reduced to a generic responsive design statement.**

Implement a small native tablet application shell that adapts to available window space.

### 7.1 Adaptive Layout Principles

Layouts must respond to:

- Available window width.
- Available window height.
- Platform size classes.
- Window resizing.
- Orientation changes.
- Multitasking configuration.
- Safe areas and system insets.
- Accessibility text scaling.

Do not use fixed device dimensions as the primary layout strategy.

Do not use hard-coded device model detection to select layouts.

Do not assume landscape orientation is always available.

Do not require landscape orientation to access application functionality.

### 7.2 Layout Modes

Establish three conceptual layout modes:

**Compact Window**

- Single primary content pane.
- Navigation can collapse or become an overlay.
- Detail content replaces the primary pane when selected.
- Navigation state must remain consistent.

**Medium Window**

- Adaptive sidebar or navigation rail.
- Primary content area.
- Optional secondary pane when available space permits.
- Avoid horizontal overcrowding.

**Expanded Window**

- Persistent or user-controllable sidebar where appropriate.
- Primary content pane.
- Optional detail or inspector pane.
- Efficient use of tablet workspace.

These are conceptual layout requirements.

They do not require identical breakpoints or component implementations across platforms.

Each platform must use its supported native adaptive APIs.

### 7.3 iPadOS Adaptive Implementation

Use SwiftUI native facilities such as:

- `NavigationSplitView`.
- `NavigationStack` where appropriate.
- SwiftUI environment size classes.
- Native toolbar and sidebar mechanisms.
- Safe area handling.
- Adaptive presentation APIs.

Choose two-column or three-column navigation only when justified by available content and space.

Do not construct a large custom window-management framework.

Use native behavior for sidebar visibility and navigation transitions.

Preserve selection state when layout changes.

### 7.4 Android Tablet Adaptive Implementation

Use Jetpack Compose with supported Material 3 adaptive capabilities.

Evaluate:

- Window Size Classes.
- Material 3 Adaptive.
- `NavigationSuiteScaffold`.
- `ListDetailPaneScaffold`.
- Navigation rail and drawer patterns.
- Window insets.
- Native adaptive navigation behavior.

Use the appropriate stable APIs supported by the verified toolchain.

Do not build a separate fixed landscape layout merely to simulate tablet behavior.

Allow the interface to recompose safely when available window space changes.

### 7.5 Layout State

Define clear ownership for:

- Selected navigation destination.
- Selected content item.
- Sidebar visibility.
- Active pane.
- Current presentation mode.
- Window-local presentation state.

Keep presentation-specific state in native applications.

Do not store native sidebar visibility or window geometry in Rust Core.

Where multiple windows exist, distinguish window-local state from genuinely shared application state.

### 7.6 Foundation Demonstration

Create a minimal tablet UI containing:

1. Native navigation area.
2. Main content area.
3. Optional detail or information pane when appropriate.
4. Hello World interaction invoking Rust.
5. A small visual demonstration of shared design tokens.

Use static foundation labels and minimal demonstration content.

Do not invent business modules merely to populate the sidebar.

The initial shell must remain useful when resized to narrower dimensions.

---

## 8. Native Tablet Navigation

Build a simple, extensible native navigation foundation.

### 8.1 Navigation Principles

Navigation must be:

- Native.
- Adaptive.
- Predictable.
- Accessible.
- Keyboard-friendly.
- Compatible with window resizing.
- Testable.
- Independent of business-specific routes.

### 8.2 iPadOS

Use the navigation pattern best suited to a productivity-oriented iPad application.

Evaluate native sidebar navigation and split-view presentation.

Support appropriate:

- Selection behavior.
- Back navigation.
- Sidebar visibility.
- Toolbar placement.
- Focus behavior.
- Compact window adaptation.

Do not implement custom navigation merely to force Android visual parity.

### 8.3 Android Tablet

Use Material 3 navigation patterns appropriate to available space.

Support appropriate:

- Navigation rail.
- Navigation drawer.
- Back navigation.
- Predictive back behavior where supported.
- Pane state restoration.
- Window size changes.

Do not force a permanent phone-style bottom navigation bar across all tablet widths.

### 8.4 Navigation Contracts

Do not place native UI route implementations inside Rust Core.

Shared business destinations may be defined later through explicit application contracts if necessary.

The initial foundation should establish native navigation structure without speculative route catalogs.

---

## 9. Tablet Window Management and Multitasking

### 9.1 General Principles

The applications must behave correctly when:

- Rotated.
- Resized.
- Backgrounded.
- Foregrounded.
- Recreated or restored by the operating system.
- Displayed beside another application where supported.

Never assume the application occupies the entire device screen.

Avoid losing navigation state during ordinary window changes.

### 9.2 iPadOS

Use native SwiftUI scene architecture.

Evaluate:

- `WindowGroup`.
- Scene lifecycle.
- Native window resizing.
- iPadOS multitasking behavior.
- Window-local state management.
- State restoration.

The initial foundation must function correctly in supported multitasking and window configurations.

Do not implement a complex multi-window workflow without a real use case.

Full independent multi-window workflows may be deferred, but their architectural boundaries must be documented.

### 9.3 Android Tablet

Respect:

- Activity lifecycle.
- Configuration changes.
- Multi-window operation.
- Resizable application windows.
- Process recreation.
- State restoration.
- Appropriate system back behavior.

Avoid unnecessary activity recreation workarounds.

Use lifecycle-aware native state management.

Do not impose restrictive orientation or window-size settings without documented justification.

### 9.4 Future Extensions

Document possible future support for:

- Multiple independent document windows.
- External displays.
- Advanced window restoration.
- Cross-window coordination.
- Drag and drop between windows.

Do not implement these capabilities during foundation setup unless essential to demonstrate basic platform correctness.

---

## 10. Tablet Input Architecture

Tablet applications must not assume all interactions come from touch.

### 10.1 Input Categories

Establish platform rules for:

- Touch.
- Hardware keyboard.
- Mouse.
- Trackpad.
- Stylus.
- Accessibility input.
- Focus navigation.

### 10.2 Touch Input

Use native controls and appropriate interaction targets.

Ensure gestures do not interfere with:

- Scrolling.
- Selection.
- Navigation.
- System gestures.
- Resizing.

### 10.3 Keyboard Input

Support native keyboard navigation in the foundation.

Provide a minimal, meaningful keyboard shortcut if the chosen shell has a suitable action.

Use platform-native shortcut APIs.

Avoid a custom global shortcut system.

Document conventions for future:

- Search.
- Save.
- Navigation.
- Refresh.
- Command discovery.

Do not implement unavailable business commands.

### 10.4 Mouse and Trackpad

Preserve native:

- Hover feedback.
- Focus.
- Click selection.
- Scrolling.
- Pointer behavior.
- Context menus where meaningful.

Do not simulate desktop behavior through unnecessary custom gesture handling.

### 10.5 Stylus

Respect platform-specific stylus APIs and conventions.

Future capabilities may include:

- Apple Pencil.
- Android stylus.
- Precision selection.
- Handwriting.
- Drawing.
- Annotations.
- Pressure-sensitive input.

Do not create a drawing engine or handwriting framework during foundation setup.

### 10.6 Input Ownership

Platform-specific input translation belongs to native presentation.

Shared application rules triggered by input belong to Rust.

Rust must not depend on physical keyboard layouts, pointer coordinates, or native stylus APIs.

---

## 11. Shared Design System

Implement the principle:

**Shared Design Language, Native Tablet UI Implementation.**

### 11.1 Canonical Design Tokens

Use one platform-neutral, version-controlled token source.

Establish semantic definitions for:

- Brand colors.
- Primary and secondary colors.
- Background.
- Surface.
- Text.
- Borders.
- Success, warning, and error.
- Typography roles.
- Font weights.
- Spacing.
- Corner radius.
- Motion semantics.
- Content density roles.
- Layout spacing conventions.

Distinguish primitive values from semantic aliases.

Support light and dark appearance.

### 11.2 Tablet Layout Tokens

Define reasonable shared semantic conventions for:

- Compact content spacing.
- Regular content spacing.
- Comfortable content spacing.
- Sidebar spacing.
- Panel spacing.
- Content margins.
- Table and list density.
- Header spacing.

Avoid making canonical values depend on one specific device model.

Shared semantic tokens must not override platform accessibility requirements or native component behavior.

### 11.3 Token Generation

Implement deterministic generation:

Canonical JSON Tokens → Token Generator → Swift Tokens + Kotlin Tokens

Generated tokens must be consumed through native SwiftUI and Compose theme layers.

Do not manually maintain duplicated design constants.

Do not edit generated token definitions.

### 11.4 Native UI Rules

**iPadOS:**

- Respect Apple Human Interface Guidelines.
- Use native SwiftUI components.
- Preserve current system visual behavior.
- Support Dynamic Type.
- Respect system appearance.
- Support native sidebar and toolbar presentation.
- Do not recreate Material Design.

**Android Tablet:**

- Respect Material 3 conventions.
- Use Jetpack Compose.
- Support adaptive navigation.
- Support font scaling.
- Respect dynamic system behavior where appropriate.
- Use native surface, elevation, and interaction conventions.
- Do not recreate Apple's system visual effects.

### 11.5 Cross-Platform Consistency

Keep consistent:

- Brand identity.
- Semantic color meaning.
- Typography hierarchy.
- Content terminology.
- General spacing rhythm.
- Error and status meaning.
- Accessibility intent.

Allow native differences in:

- Navigation controls.
- Toolbar presentation.
- Icons.
- Motion.
- Component shape.
- Pointer interaction.
- Dialog presentation.
- System visual effects.

### 11.6 Foundation Validation

The Hello World tablet shell must demonstrate:

- Shared semantic colors.
- Typography hierarchy.
- Spacing.
- Surface definitions.
- Light and dark appearance.
- Native adaptive behavior.

Do not create a large enterprise component library at this stage.

---

## 12. Shared Configuration

Establish canonical configuration conventions.

Distinguish:

- Build-time configuration.
- Runtime configuration.
- Environment definitions.
- Public application settings.
- Platform-specific configuration.
- Future feature flags.

Use shared schemas only for values that genuinely require cross-platform consistency.

Native platform configuration may remain native.

Never commit:

- Secrets.
- Signing credentials.
- Private keys.
- Production tokens.
- Confidential environment values.

Do not implement a remote configuration service.

Document versioning, validation, and environment ownership.

---

## 13. Shared Localization

Establish one canonical source for shared localization content.

Define:

- Stable localization keys.
- Locale naming conventions.
- Fallback behavior.
- Placeholder validation.
- Missing translation detection.
- Shared terminology.
- Resource generation or mapping.

Respect native:

- Date formatting.
- Number formatting.
- Pluralization.
- Text direction.
- Locale-sensitive layouts.
- Accessibility labels.

Consider longer localized text in sidebar and multi-pane layouts.

Do not independently maintain duplicated translation catalogs.

Implement only the minimal localization example required by the foundation.

---

## 14. Shared Assets

Establish conventions for canonical brand assets.

Define:

- Asset naming.
- Source formats.
- Platform exports.
- Light and dark variants.
- Resolution requirements.
- Optimization.
- Versioning.
- Ownership.

Preserve native icon conventions.

Do not force one platform's system iconography onto the other.

Avoid unnecessary artwork during initial setup.

Document where future tablet-specific illustrations and high-resolution assets belong.

---

## 15. Shared Contracts

Establish long-term conventions for:

- Rust DTOs.
- UniFFI interfaces.
- Typed errors.
- Machine-readable error codes.
- Nullability.
- Compatibility.
- Versioning.
- Async operations.
- Cancellation.
- Resource ownership.
- Native capability interfaces.

Rust and UniFFI must remain authoritative for cross-language application contracts.

Do not expose Rust implementation internals.

Do not create speculative business DTOs.

Future OpenAPI transport contracts must remain distinct from application and FFI contracts.

---

## 16. Shared Tooling and Code Generation

Establish deterministic tooling for:

- UniFFI bindings.
- Design tokens.
- Shared resources.
- Schema validation.
- Build automation.
- Architecture compliance.

Generated outputs must have documented ownership.

Never manually edit generated files.

Generation must be reproducible.

Pin tool versions where appropriate.

### iPadOS Integration

Create a reproducible process for:

- Building Rust for supported Apple targets.
- Generating Swift bindings.
- Packaging and linking native Rust libraries.
- Supporting iPad simulator builds.
- Supporting physical iPad builds.

Use an appropriate Apple framework packaging strategy, such as XCFramework, where justified.

### Android Tablet Integration

Create a reproducible process for:

- Building Rust for selected Android ABIs.
- Generating Kotlin bindings.
- Packaging native libraries.
- Integrating Rust with Gradle.
- Supporting tablet emulators.
- Supporting physical Android tablets.

Document which ABIs are supported and why.

Do not assume one binary works across all architectures.

Do not commit unnecessary generated binaries.

---

## 17. Architecture Compliance

Implement lightweight automated checks where technically practical.

Validate:

1. Rust formatting.
2. Rust linting.
3. Rust unit tests.
4. Cargo dependency direction.
5. Prohibited dependencies.
6. UniFFI generation consistency.
7. Design token schemas.
8. Generated token consistency.
9. Shared resource schemas.
10. Localization keys and placeholders.
11. Generated-file policies.
12. Documentation presence.
13. iPadOS build integration.
14. Android Tablet build integration.
15. Native architecture boundaries.
16. Shared contract consistency.

Document compliance rules in:

`docs/quality/architecture-compliance.md`

Distinguish automated checks from rules requiring human architectural review.

Do not create an oversized custom governance framework.

Automated tools cannot reliably identify every duplicated business algorithm or accessibility defect.

---

## 18. Agent Governance

Create a root `AGENTS.md`.

This file must be concise, authoritative, and suitable for future coding agents.

Every agent must follow this workflow.

### Before Implementation

1. Inspect the repository.
2. Read AGENTS.md.
3. Read relevant architectural documentation.
4. Identify the responsible architectural layer.
5. Check existing implementations.
6. Check for duplicated responsibilities.
7. Identify permitted dependencies.
8. Determine affected platforms.
9. Determine adaptive UI requirements.
10. Determine testing requirements.

### During Implementation

1. Follow ownership boundaries.
2. Respect dependency direction.
3. Reuse authoritative implementations.
4. Use shared design tokens.
5. Use shared resources.
6. Keep generated code isolated.
7. Avoid speculative abstractions.
8. Preserve native platform conventions.
9. Avoid fixed-size tablet-only layout assumptions.
10. Support relevant window sizes.
11. Preserve accessibility.
12. Update architecture documentation when necessary.

### After Implementation

1. Run relevant tests.
2. Run architecture checks.
3. Validate generated artifacts.
4. Verify affected platform builds.
5. Check adaptive layout behavior.
6. Check keyboard and pointer behavior where applicable.
7. Document actual test results.
8. Report limitations accurately.

### Multi-Agent Rules

Future coding agents must not independently introduce duplicate application logic.

An agent working on SwiftUI must not silently replicate Rust rules.

An agent working on Compose must not introduce separate shared contract definitions.

An agent modifying canonical design tokens must regenerate or validate affected platform outputs.

An agent changing a shared contract must evaluate both tablet applications.

Material architectural changes require ADR documentation.

`AGENTS.md` must link to detailed documentation rather than duplicating it.

---

## 19. Service and Module Rules

Define future service development conventions without implementing business services yet.

Future services must have:

- One responsibility.
- One authoritative owner.
- Explicit public interfaces.
- Defined dependency boundaries.
- Structured errors.
- Testable behavior.
- Documented lifecycle expectations.

Do not allow services to access another service's private implementation directly.

Avoid circular dependencies.

Before introducing another crate or service, determine whether an existing module can own the functionality.

Do not create service scaffolding for speculative enterprise modules.

---

## 20. Enterprise Foundation Quality Requirements

Enterprise-ready does not mean implementing all enterprise business capabilities immediately.

The foundation must establish quality practices that future development can follow.

### 20.1 Maintainability

Use:

- Clear module boundaries.
- Explicit interfaces.
- Consistent naming.
- Predictable dependency direction.
- Documented extension points.

### 20.2 Reliability

Avoid hidden lifecycle assumptions.

Do not assume:

- The application always stays foregrounded.
- The window never resizes.
- The device has a keyboard.
- The network is always available.
- The process is never terminated.
- Only one app window can ever exist.

Document future lifecycle and recovery responsibilities without implementing speculative persistence systems.

### 20.3 Security

Establish security development rules for:

- Dependency management.
- Secret handling.
- Build configuration.
- Native platform permissions.
- FFI safety.
- Unsafe Rust review.
- Sensitive logging.
- Production build artifacts.

Do not introduce authentication, encryption services, or storage engines without requirements.

### 20.4 Observability

Establish basic development logging conventions where meaningful.

Avoid a full telemetry stack during foundation setup.

Future observability must respect privacy and platform constraints.

### 20.5 Accessibility

Accessibility is mandatory from the beginning.

Support:

- Screen readers.
- Semantic labels.
- Focus order.
- Font scaling.
- Color contrast.
- Accessible interaction targets.
- Reduced motion where applicable.
- Keyboard navigation.
- Meaningful status announcements.

Use platform-native accessibility APIs.

### 20.6 Performance

Keep the foundation lightweight.

Avoid unnecessary startup work.

Avoid blocking the native UI thread with expensive Rust calls.

Future long-running shared operations must use appropriate asynchronous contracts.

Do not introduce speculative background workers.

---

## 21. Testing Strategy

Implement foundation-level testing.

### Rust

- Core unit tests.
- UniFFI export smoke tests.
- Formatting and lint checks.
- Contract validation.

### iPadOS

- Swift binding integration.
- Hello World invocation.
- Native app launch.
- Adaptive sidebar behavior.
- Compact and regular window layouts.
- Portrait and landscape behavior.
- Basic keyboard navigation.
- Shared token integration.
- Light and dark appearance.
- Basic accessibility smoke tests.

### Android Tablet

- Kotlin binding integration.
- Hello World invocation.
- Native app launch.
- Medium and expanded window layouts.
- Compact resized-window behavior.
- Navigation rail or drawer adaptation.
- Portrait and landscape behavior.
- Basic keyboard and pointer navigation.
- Shared token integration.
- Light and dark appearance.
- Basic accessibility smoke tests.

### Shared Resources

- Token schema validation.
- Token generation consistency.
- Localization key validation.
- Configuration schema validation where implemented.

### Architecture

- Dependency boundaries.
- Generated-code consistency.
- Documentation compliance.
- Agent governance compliance.

### Tablet Testing Matrix

Document and test, where environments are available:

| Scenario | iPadOS | Android Tablet |
|---|---|---|
| Portrait | Required | Required |
| Landscape | Required | Required |
| Narrow window | Required | Required |
| Expanded window | Required | Required |
| Window resizing | Required | Required |
| Multitasking | Required | Required |
| Touch interaction | Required | Required |
| Keyboard navigation | Required | Required |
| Pointer interaction | Required | Required |
| Light appearance | Required | Required |
| Dark appearance | Required | Required |
| Accessibility scaling | Required | Required |

Testing must validate layout behavior, not merely compile applications.

Do not create large end-to-end testing infrastructure for business features that do not exist.

---

## 22. Build System and CI/CD

Provide reproducible commands for:

- Building Rust.
- Testing Rust.
- Generating UniFFI bindings.
- Building Rust libraries for Apple targets.
- Building Rust libraries for Android ABIs.
- Integrating Swift bindings.
- Integrating Kotlin bindings.
- Generating design tokens.
- Validating shared resources.
- Building iPadOS.
- Building Android Tablet.
- Running foundation tests.
- Running architecture compliance checks.

Use platform-appropriate tooling.

### GitHub Actions

Create workflows for:

- Rust format, lint, and tests.
- UniFFI generation validation.
- Design token validation.
- Shared resource validation.
- Architecture compliance.
- iPadOS build verification.
- Android Tablet build verification.

Use macOS runners where Apple builds require them.

Pin compatible toolchains and dependencies where appropriate.

Keep signing credentials outside version control.

Do not implement App Store or Google Play deployment pipelines during this phase.

Do not claim a build or test succeeded unless it actually ran successfully.

Clearly distinguish configuration validation, compilation, simulator testing, and physical-device verification.

---

## 23. Documentation Requirements

Create authoritative documentation covering:

### Architecture

- System overview.
- Ownership matrix.
- Dependency direction.
- Repository structure.
- Layer boundaries.
- Extension procedure.

### Native Tablet Development

- iPadOS conventions.
- Android Tablet conventions.
- Adaptive layouts.
- Sidebar and navigation patterns.
- Window management.
- Multitasking.
- Input interactions.
- Accessibility.
- State restoration boundaries.

### Rust and Interoperability

- Rust conventions.
- UniFFI contracts.
- Binding generation.
- Dependency rules.
- Error conventions.
- FFI ownership and lifecycle.

### Shared Design System

- Token schema.
- Semantic naming.
- Tablet spacing.
- Native theme mapping.
- Component conventions.
- Accessibility.

### Shared Resources

- Configuration.
- Localization.
- Assets.
- Versioning.
- Generation.

### Quality

- Automated compliance.
- Testing matrix.
- Build verification.
- CI workflows.
- Security baseline.
- Unverified capabilities.

Documentation must reflect actual implemented behavior.

Future capabilities must not be documented as already implemented.

---

## 24. Future Development Policy

The following features are explicitly outside the initial scope:

- Authentication.
- User and role management.
- Enterprise identity providers.
- Customer management.
- ERP modules.
- Dashboard business metrics.
- REST and GraphQL clients.
- OpenAPI-generated Rust clients.
- SQLite persistence.
- Offline synchronization.
- Conflict resolution.
- Background uploads.
- Image processing.
- Advanced stylus drawing.
- Document editing.
- Complex drag and drop workflows.
- Multiple independent business windows.
- External display workflows.
- Runtime feature flag engines.
- Large enterprise component libraries.
- Phone-specific application variants.
- Desktop applications.

Each future capability requires separate architectural analysis and implementation planning.

Future development must preserve:

- Single authoritative ownership.
- Explicit contracts.
- Native tablet presentation.
- Adaptive layouts.
- Dependency boundaries.
- Canonical design definitions.
- Shared resource conventions.
- Agent governance.
- Automated architecture compliance.

Do not introduce speculative implementation dependencies for deferred capabilities.

---

## 25. Foundation Acceptance Criteria

The foundation is complete only when the following criteria are satisfied.

### Shared Core

1. Cargo Workspace builds successfully.
2. Rust Core and UniFFI boundaries are separated.
3. Swift bindings generate correctly.
4. Kotlin bindings generate correctly.
5. Both applications invoke the same Rust Hello World function.
6. Both applications display the Rust result.

### Native Tablet Apps

7. iPadOS application launches successfully.
8. Android Tablet application launches successfully.
9. iPadOS uses genuine SwiftUI rendering.
10. Android Tablet uses genuine Compose rendering.
11. Both applications have functional native tablet navigation.
12. Both applications expose an adaptive navigation and content shell.
13. Both applications support portrait and landscape layout adaptation.
14. Both applications adapt to narrower available windows.
15. Both applications demonstrate expanded tablet layouts.
16. Navigation state remains coherent during layout changes.
17. Basic keyboard navigation is functional.
18. Native pointer and touch interactions are preserved.

### Shared Foundation

19. Canonical design tokens exist.
20. Both applications consume generated or reproducibly mapped tokens.
21. Light and dark appearance are demonstrated.
22. Shared configuration conventions are documented.
23. Shared localization conventions and a minimal example exist.
24. Shared asset ownership conventions are documented.
25. Shared contract conventions are established.

### Architecture and Quality

26. Architecture compliance checks are configured.
27. Root AGENTS.md contains enforceable development rules.
28. Architecture and tablet layout documentation exist.
29. Reproducible build scripts are functional.
30. GitHub Actions workflows are configured.
31. Relevant tests are executed.
32. Actual verification results are documented.
33. Unverified targets are explicitly reported.
34. No unnecessary business-specific services are implemented.

Do not mark an acceptance criterion as passed without corresponding evidence.

If the execution environment cannot build or test a platform, record that criterion as unverified.

---

## 26. Execution Instructions

Begin by inspecting the current repository.

If the repository is empty, create the foundation from scratch.

Follow this sequence.

### Step 1 — Architecture Analysis

Define:

- Minimal architecture.
- Ownership matrix.
- Dependency boundaries.
- Native tablet presentation strategy.
- Adaptive layout approach.
- Repository structure.

### Step 2 — Toolchain Verification

Verify and select compatible stable versions of:

- Rust.
- Cargo.
- UniFFI.
- Swift.
- Xcode.
- iPadOS SDK.
- Kotlin.
- Gradle.
- Android Gradle Plugin.
- Android SDK.
- Jetpack Compose.
- Material 3 Adaptive libraries.

Document compatibility decisions.

### Step 3 — Repository Foundation

Create:

- Cargo Workspace.
- Native tablet project foundations.
- Shared directories.
- Documentation.
- AGENTS.md.

### Step 4 — Rust and UniFFI

Implement one Rust Hello World function.

Generate Swift and Kotlin bindings.

Verify bindings and native library integration.

### Step 5 — Native Tablet Integration

Integrate Rust Hello World into both native applications.

Use real native rendering.

Do not duplicate Hello World logic.

### Step 6 — Adaptive Tablet Shell

Implement a minimal native adaptive shell on each platform.

Demonstrate:

- Native navigation area.
- Main content.
- Optional secondary pane.
- Window-size adaptation.
- Portrait and landscape behavior.

### Step 7 — Design System

Establish:

- Canonical tokens.
- Deterministic generation.
- Native theme integration.
- Light and dark appearance.

### Step 8 — Shared Resources

Establish:

- Configuration conventions.
- Localization conventions.
- Asset ownership.
- Contract conventions.

Implement only minimal examples required for validation.

### Step 9 — Architecture Compliance

Implement lightweight checks for enforceable architectural rules.

### Step 10 — Build and CI

Configure:

- Reproducible build scripts.
- Automated tests.
- GitHub Actions.
- Platform verification commands.

### Step 11 — Tablet Validation

Validate supported scenarios:

- iPadOS portrait and landscape.
- Android Tablet portrait and landscape.
- Narrow and expanded windows.
- Native navigation.
- Keyboard and pointer basics.
- Shared Rust interoperability.
- Shared design token integration.

### Step 12 — Verification Report

Produce a final report describing:

1. Implemented architecture.
2. Repository structure.
3. Verified toolchain versions.
4. Generated bindings.
5. Working native applications.
6. Adaptive layout behavior.
7. Implemented design tokens.
8. Shared resource conventions.
9. Executed tests.
10. Passed acceptance criteria.
11. Failed or unverified criteria.
12. Known limitations.
13. Recommended next development phases.

Report only actual results.

Do not expand beyond the initial foundation scope.

Do not implement speculative application services.

Do not introduce unnecessary infrastructure.

Do not redesign established boundaries without documented architectural justification.

---

## FINAL MANDATORY PRINCIPLES

**1. One authoritative owner per responsibility.**

**2. Rust owns shared application behavior and business rules.**

**3. Swift and SwiftUI own native iPadOS presentation.**

**4. Kotlin and Jetpack Compose own native Android Tablet presentation.**

**5. UniFFI provides the explicit cross-language interoperability boundary.**

**6. Native adaptive layouts are mandatory, not optional.**

**7. A tablet application must adapt to its available window, not merely its physical screen size.**

**8. Shared design language must coexist with native platform conventions.**

**9. Canonical design tokens and shared resources must not be duplicated manually.**

**10. Generated code must be reproducible and never manually maintained.**

**11. Repository structure defines enforceable architecture boundaries.**

**12. AGENTS.md and docs/ preserve consistency across coding agents.**

**13. Automated testing and architecture compliance protect the foundation.**

**14. Accessibility, keyboard navigation, and window adaptation are first-class architectural requirements.**

**15. Future functionality must extend the foundation through deliberate architecture analysis and PRDs.**

**16. Initial implementation remains limited to a minimal functional foundation, including a native adaptive tablet shell and shared Rust Hello World.**

**17. Enterprise readiness means disciplined architecture, maintainability, reliability, and verifiable quality—not premature implementation of business features.**

Build a stable, maintainable, verifiable, enterprise-oriented native tablet foundation that future coding agents can extend without duplicated implementations, unclear ownership, or fragile tablet-specific assumptions.

**Start with repository inspection and architecture analysis, then proceed through scaffold implementation and actual verification. Do not stop after generating an architecture proposal.**
