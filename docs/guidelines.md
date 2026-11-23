# Engineering Guidelines

## Purpose

These guidelines define the engineering standards and architectural principles that must be followed when developing, modifying, or extending this codebase.

The primary objectives are to make the codebase:

- **Maintainable:** Easy to modify without introducing unintended side effects.
- **Readable:** Easy to understand without requiring extensive investigation.
- **Debuggable:** Easy to trace, diagnose, and resolve issues.
- **Extensible:** Easy to introduce new features without restructuring existing code.
- **Reusable:** Avoid unnecessary duplication through well-designed shared components and utilities.
- **Modular:** Keep features independent and minimize unnecessary dependencies.
- **Testable:** Make business logic and individual components easy to test.

These guidelines apply to all existing and newly introduced code.

---

# 1. Architecture and Code Organization

## 1.1 Follow Clean Architecture Principles

Organize the codebase into clearly defined layers with specific responsibilities.

Each layer must have a well-defined purpose and should not take responsibility for another layer's work.

Recommended logical layers:

1. **Presentation Layer**
   - UI components.
   - Screens and pages.
   - User interactions.
   - UI state management.
   - Presentation-specific logic.

2. **Application Layer**
   - Use cases.
   - Application services.
   - Feature orchestration.
   - Workflow coordination.
   - Application-level business operations.

3. **Domain Layer**
   - Business entities.
   - Business rules.
   - Domain models.
   - Domain services.
   - Repository contracts.
   - Business validations.

4. **Data Layer**
   - Repository implementations.
   - API clients.
   - Database operations.
   - Data sources.
   - DTOs and serialization.
   - External service integrations.

5. **Infrastructure / Platform Layer**
   - Logging.
   - File system access.
   - Platform-specific implementations.
   - Dependency injection infrastructure.
   - External integrations.

The exact implementation may vary depending on project complexity, but responsibilities must remain separated.

## 1.2 Enforce Dependency Direction

Dependencies should flow inward toward business logic.

- Presentation can depend on application abstractions.
- Application can depend on domain abstractions.
- Data and infrastructure can implement domain contracts.
- Domain must not depend on presentation, databases, frameworks, or external services.

Avoid circular dependencies between layers.

## 1.3 Organize Code by Feature

Prefer feature-oriented organization over placing every file of the same technical type into a global directory.

Example:

```text
src/
├── core/
│   ├── errors/
│   ├── logging/
│   ├── networking/
│   ├── utilities/
│   └── dependency_injection/
│
├── shared/
│   ├── components/
│   ├── models/
│   └── contracts/
│
├── features/
│   ├── authentication/
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── domain/
│   │   └── data/
│   │
│   ├── dashboard/
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── domain/
│   │   └── data/
│   │
│   └── settings/
│       ├── presentation/
│       ├── application/
│       ├── domain/
│       └── data/
│
└── main/
```

Do not create unnecessary layers or directories for the sake of following a folder structure. Introduce abstractions when they provide meaningful separation.

## 1.4 Keep Features Independent

Each feature should own its implementation and internal logic.

- A feature must not directly manipulate another feature's internal state.
- Avoid importing private implementation details from another feature.
- Communicate through explicitly defined interfaces, contracts, events, or application services.
- Avoid shared mutable state between unrelated features.
- Do not create dependencies between features unless there is a genuine business requirement.

A feature should ideally be understandable, testable, and modifiable independently.

## 1.5 Avoid God Classes and God Modules

A class, module, or service should have one clear responsibility.

Avoid classes that simultaneously handle:

- API communication.
- Business logic.
- State management.
- UI rendering.
- Data transformation.
- Navigation.
- Error handling.

Split responsibilities into focused components.

---

# 2. Component Design

## 2.1 Build Small, Focused Components

Every component should have a clear and limited responsibility.

- Prefer small components over large components.
- Break complex components into smaller logical units.
- Keep rendering and business logic separate.
- Avoid deeply nested component structures.
- Avoid components with excessive conditional behavior.

A component should be understandable without needing to understand the entire application.

## 2.2 Design Components for Reusability

Before implementing a component, determine whether it represents:

- A reusable generic component.
- A feature-specific component.
- A page-level component.
- A composition of existing components.

Place reusable components in shared locations and feature-specific components within their owning feature.

Do not move components into a global shared directory simply because they are used more than once.

## 2.3 Use Explicit Component Interfaces

Component inputs and outputs must be clear.

- Use descriptive property names.
- Define required and optional parameters explicitly.
- Avoid excessive configuration parameters.
- Avoid passing entire application objects when only a few values are required.
- Use callbacks, events, or explicit contracts for communication.
- Avoid hidden dependencies on global state.

## 2.4 Avoid Unnecessary Component Coupling

Components should not know unnecessary implementation details about their parent or sibling components.

Prefer composition over inheritance where appropriate.

Avoid:

- Directly accessing another component's internal state.
- Modifying parent state through hidden references.
- Depending on specific screen implementations.
- Hardcoding feature-specific behavior into generic components.

## 2.5 Keep Components Predictable

Given the same inputs and state, a component should produce predictable behavior.

Avoid hidden side effects during rendering or component initialization.

Keep asynchronous operations, subscriptions, and lifecycle management explicit.

---

# 3. Reusable Utilities and Shared Code

## 3.1 Centralize Truly Reusable Logic

Create shared utilities for functionality that is genuinely common across multiple parts of the application.

Examples:

- Date and time formatting.
- String manipulation.
- Validation helpers.
- Data transformation.
- File operations.
- Common error handling.
- Logging.
- Networking helpers.
- Collection operations.
- Common mathematical operations.

Avoid duplicating the same logic across features.

## 3.2 Do Not Create Premature Abstractions

Do not create a generic utility simply because two pieces of code look similar.

Before extracting shared logic, evaluate:

- Whether the behavior is actually identical.
- Whether the abstraction has a clear purpose.
- Whether it will reduce maintenance.
- Whether future changes to one implementation could affect the other.

Duplication is sometimes preferable to an incorrect abstraction.

## 3.3 Keep Utilities Independent

Utilities should:

- Have a focused responsibility.
- Avoid unnecessary dependencies.
- Avoid accessing global application state.
- Avoid performing unrelated operations.
- Be independently testable.
- Have predictable inputs and outputs.

Prefer pure functions wherever practical.

## 3.4 Establish Clear Ownership

Use the following distinction:

- `core`: Fundamental application-wide infrastructure.
- `shared`: Reusable components, models, and contracts.
- `features`: Feature-specific implementation.
- `utilities`: Generic, reusable helper functionality.

Do not use shared directories as a dumping ground for unrelated code.

---

# 4. Loose Coupling and Modularity

## 4.1 Depend on Abstractions

Prefer interfaces and contracts over direct dependencies on concrete implementations.

For example:

A business operation should depend on a repository interface rather than directly depending on a particular REST client or database implementation.

This allows implementations to change without affecting consumers.

## 4.2 Use Dependency Injection

Dependencies should be provided explicitly rather than created internally throughout the codebase.

Benefits:

- Easier testing.
- Easier replacement of implementations.
- Reduced coupling.
- Clear dependency ownership.
- Better control over object lifecycles.

Avoid unnecessary service locators and hidden global dependencies.

## 4.3 Define Module Boundaries

Each module should clearly define:

- What it owns.
- What it exposes.
- What it depends on.
- What it must not access.

Expose only the public interfaces required by other modules.

Keep implementation details private.

## 4.4 Minimize Cross-Feature Communication

When features need to communicate, prefer:

1. Explicit application-level interfaces.
2. Events or message-based communication where appropriate.
3. Shared domain contracts.
4. Dedicated orchestration services.

Avoid direct dependencies on internal feature classes.

Do not introduce an event bus or messaging abstraction for simple operations that can be handled through a direct interface.

## 4.5 Avoid Circular Dependencies

Circular dependencies indicate incorrect module boundaries.

Refactor the architecture instead of introducing workarounds to maintain circular references.

---

# 5. Naming Conventions and Readability

## 5.1 Use Meaningful Names

Names must communicate intent.

Prefer:

- `UserRepository` over `UserRepo`.
- `calculateTotalPrice` over `calculate`.
- `AuthenticationService` over `AuthManager`.
- `isUserAuthenticated` over `check`.
- `fetchUserProfile` over `getData`.

Avoid ambiguous names such as:

- `data`
- `manager`
- `helper`
- `processor`
- `handler`
- `common`
- `misc`

These names are acceptable only when their responsibility is genuinely clear from context.

## 5.2 Write Self-Explanatory Code

Code should communicate what it does without requiring extensive comments.

Prefer descriptive variables, small functions, clear conditions, and straightforward control flow.

Avoid:

- Deeply nested conditions.
- Extremely long functions.
- Unnecessary one-line expressions.
- Complex ternary operations.
- Cryptic abbreviations.
- Magic numbers and unexplained strings.

## 5.3 Follow Consistent Formatting

Maintain consistent:

- Indentation.
- Naming conventions.
- File naming.
- Import ordering.
- Function organization.
- Bracket placement.
- Code formatting.

Use automated formatters and linters wherever available.

## 5.4 Write Comments for Intent

Comments should explain:

- Why a particular approach was chosen.
- Important architectural decisions.
- Non-obvious business rules.
- Workarounds and external limitations.
- Complex algorithms.
- Unexpected behavior.

Avoid comments that simply repeat what the code already says.

Keep comments updated when implementation changes.

---

# 6. State Management

## 6.1 Keep State Ownership Clear

Every piece of state should have a clearly defined owner.

Prefer the narrowest scope that satisfies the requirement.

- Component state for local UI behavior.
- Feature state for feature-level operations.
- Application state for genuinely global information.
- Persistent storage for data that must survive application restarts.

Avoid unnecessarily global state.

## 6.2 Separate UI State and Business State

Do not mix presentation-specific state with core business rules.

UI state may include loading indicators, selected tabs, visibility, and temporary form values.

Business state should represent actual application or domain information.

## 6.3 Make State Transitions Predictable

State updates should be explicit and traceable.

Avoid modifying state from unrelated components or services.

Handle loading, success, empty, and error states consistently.

---

# 7. Error Handling and Debugging

## 7.1 Handle Errors Explicitly

Do not silently swallow exceptions.

Every error should either:

- Be handled meaningfully.
- Be propagated to an appropriate layer.
- Be transformed into a meaningful application error.
- Be logged with relevant diagnostic context.

Avoid broad exception handling unless there is a clear recovery strategy.

## 7.2 Use Structured Error Types

Prefer meaningful error categories instead of relying entirely on generic exceptions or strings.

Examples:

- Network errors.
- Authentication errors.
- Validation errors.
- Permission errors.
- Resource-not-found errors.
- Database errors.
- Unexpected application errors.

Preserve the original error and stack trace when propagating errors.

## 7.3 Implement Consistent Logging

Use a centralized logging mechanism.

Logs should include useful context such as:

- Operation being performed.
- Feature or module.
- Relevant identifiers.
- Error details.
- Stack traces.
- Execution context where appropriate.

Use appropriate log levels:

- DEBUG: Detailed diagnostic information.
- INFO: Important application events.
- WARNING: Unexpected but recoverable situations.
- ERROR: Operations that failed.
- FATAL: Critical failures where supported.

Never log passwords, authentication tokens, secrets, or sensitive personal data.

## 7.4 Make Debugging Easy

Code should make it easy to trace an operation from its entry point to its completion.

Prefer explicit execution flows over hidden callbacks, implicit side effects, and deeply chained operations.

For asynchronous operations:

- Handle failures explicitly.
- Avoid unhandled futures or promises.
- Manage cancellation where appropriate.
- Prevent stale operations from modifying newer state.
- Clean up subscriptions and resources.

---

# 8. API and Data Layer

## 8.1 Separate API Communication from Business Logic

API clients should handle communication, not business decisions.

Keep responsibilities separate:

- API client: HTTP requests and responses.
- DTO: External data representation.
- Mapper: DTO-to-domain conversion.
- Repository: Data access abstraction and coordination.
- Use case: Application or business operation.

## 8.2 Avoid Leaking External Data Models

Do not expose API-specific response objects throughout the application.

Convert external data into appropriate internal models.

This prevents API changes from spreading throughout unrelated features.

## 8.3 Centralize Network Configuration

Maintain centralized configuration for:

- Base URLs.
- Headers.
- Authentication.
- Timeouts.
- Interceptors.
- Retry policies.
- Response handling.
- Network logging.

Avoid duplicating network configuration across features.

## 8.4 Handle Network Failures

Account for:

- Timeouts.
- Connection failures.
- Invalid responses.
- Unauthorized requests.
- Server errors.
- Rate limiting.
- Partial failures.

Retry only when the operation is safe to retry. Use appropriate backoff strategies.

---

# 9. Testing and Quality Assurance

## 9.1 Write Tests for Important Logic

Prioritize tests for:

- Business rules.
- Use cases.
- Data transformations.
- Utilities.
- Validation.
- State transitions.
- Error handling.
- Feature integrations.

## 9.2 Follow Testing Layers

Use appropriate testing levels:

1. Unit tests: Individual functions, classes, and business rules.
2. Component tests: Individual components and their behavior.
3. Integration tests: Communication between modules and services.
4. End-to-end tests: Important complete user workflows.

## 9.3 Design for Testability

Avoid hardcoded dependencies, hidden global state, and tightly coupled implementations.

Use dependency injection and clear interfaces to make dependencies replaceable during testing.

## 9.4 Prevent Regressions

When fixing a bug:

- Identify the root cause.
- Add a regression test where practical.
- Verify related functionality.
- Avoid introducing unrelated changes.

---

# 10. Performance and Resource Management

Performance should be considered during implementation, but optimization must be based on actual requirements and measurements.

Guidelines:

- Avoid unnecessary computations.
- Avoid repeated expensive operations.
- Cache only when there is a clear benefit.
- Avoid unnecessary object creation.
- Release resources appropriately.
- Clean up listeners and subscriptions.
- Avoid memory leaks.
- Use pagination for large datasets.
- Avoid blocking critical execution paths.
- Profile before optimizing performance-sensitive code.

Do not sacrifice readability for speculative performance improvements.

---

# 11. Configuration and Environment Management

Keep environment-specific configuration separate from application logic.

Examples:

- Development configuration.
- Staging configuration.
- Production configuration.
- API endpoints.
- Feature flags.
- Build configuration.

Never hardcode environment-specific values throughout the codebase.

Never commit secrets, credentials, private keys, or access tokens.

Use centralized configuration management.

---

# 12. Documentation

Documentation must evolve alongside the implementation.

Maintain documentation for:

- Project architecture.
- Module responsibilities.
- Important workflows.
- Public interfaces.
- Complex business rules.
- Configuration.
- Build and execution instructions.
- Development setup.
- Important architectural decisions.

Use Architecture Decision Records (ADRs) for significant architectural choices.

Documentation should explain the reasoning behind important design decisions, not merely describe the folder structure.

---

# 13. Adding New Features

Every new feature must follow a consistent development process.

Before implementation:

1. Understand the existing architecture.
2. Identify the appropriate feature or module.
3. Identify existing reusable components and utilities.
4. Identify required dependencies.
5. Define clear responsibilities.
6. Determine whether new abstractions are actually necessary.
7. Consider testing requirements.

During implementation:

1. Keep implementation within the owning feature.
2. Follow established architectural boundaries.
3. Reuse existing abstractions when appropriate.
4. Avoid duplicating existing functionality.
5. Keep business logic separate from presentation.
6. Handle errors explicitly.
7. Add meaningful logging.
8. Write tests for important behavior.

After implementation:

1. Verify existing functionality.
2. Run relevant tests.
3. Check for unintended dependencies.
4. Check for duplicated logic.
5. Update documentation.
6. Review the overall maintainability of the change.

---

# 14. Modifying Existing Code

When modifying existing functionality:

- Understand the existing implementation before changing it.
- Identify all affected modules and dependencies.
- Preserve existing behavior unless the requirement explicitly changes it.
- Avoid unnecessary refactoring during unrelated feature development.
- Do not introduce duplicate implementations.
- Update dependent tests and documentation.
- Check for regressions.

Prefer small, focused changes over large, unrelated modifications.

When refactoring, preserve externally observable behavior unless a behavior change is intentional.

---

# 15. Anti-Patterns to Avoid

The following practices should generally be avoided:

- God classes and God modules.
- Circular dependencies.
- Tight coupling between features.
- Business logic inside UI components.
- Database or API calls directly from presentation components.
- Unnecessary global state.
- Excessive inheritance.
- Premature abstractions.
- Duplicate utility implementations.
- Overly generic helper classes.
- Deeply nested conditional logic.
- Large functions with multiple responsibilities.
- Silent exception handling.
- Hardcoded configuration.
- Magic values.
- Unnecessary dependencies.
- Uncontrolled side effects.
- Unnecessary framework-specific logic in the domain layer.
- Overengineering simple requirements.
- Refactoring unrelated code without a clear reason.

---

# 16. Code Review Checklist

Before considering any implementation complete, verify the following:

## Architecture
- [ ] Does the code belong to the correct layer?
- [ ] Are responsibilities clearly separated?
- [ ] Are dependency directions correct?
- [ ] Are feature boundaries respected?
- [ ] Have circular dependencies been avoided?

## Components and Reusability
- [ ] Are components focused and small?
- [ ] Are component interfaces clear?
- [ ] Is existing reusable functionality being reused?
- [ ] Have unnecessary abstractions been avoided?
- [ ] Is shared code genuinely reusable?

## Readability
- [ ] Are names meaningful?
- [ ] Are functions and classes easy to understand?
- [ ] Is the control flow straightforward?
- [ ] Are comments useful and accurate?
- [ ] Is formatting consistent?

## Debugging and Reliability
- [ ] Are errors handled explicitly?
- [ ] Is useful diagnostic logging available?
- [ ] Are asynchronous operations handled safely?
- [ ] Are resources cleaned up?
- [ ] Can the execution flow be traced?

## Testing
- [ ] Are important business rules tested?
- [ ] Are edge cases covered?
- [ ] Are error scenarios tested?
- [ ] Have regression risks been considered?

## Extensibility
- [ ] Can this functionality be extended without modifying unrelated features?
- [ ] Are dependencies replaceable?
- [ ] Are public interfaces clearly defined?
- [ ] Can this implementation evolve without major architectural changes?

---

# 17. Fundamental Engineering Principles

All engineering decisions should follow these principles:

1. **Simplicity over complexity:** Choose the simplest design that correctly satisfies the requirement.
2. **Separation of concerns:** Every module should have a clearly defined responsibility.
3. **Single responsibility:** A component or class should have one primary reason to change.
4. **High cohesion:** Related functionality should remain together.
5. **Low coupling:** Unrelated modules should remain independent.
6. **Composition over inheritance:** Prefer combining focused components over building deep inheritance hierarchies.
7. **Explicit over implicit:** Make dependencies, behavior, and side effects visible.
8. **Reuse over duplication:** Reuse established functionality when the abstraction is appropriate.
9. **Testability by design:** New code should be easy to verify independently.
10. **Consistency over personal preference:** Follow established project conventions.
11. **Evolution over premature optimization:** Design for reasonable future changes without building unnecessary complexity today.
12. **Maintainability over cleverness:** Prefer understandable code over unnecessarily sophisticated implementations.

---

# Final Rule

Every code change must improve or preserve the overall quality of the codebase.

Do not introduce unnecessary complexity, dependencies, duplication, or architectural violations to implement a feature quickly.

When multiple solutions are possible, prefer the one that:

- Has fewer unnecessary dependencies.
- Has clearer responsibilities.
- Is easier to understand.
- Is easier to test.
- Is easier to debug.
- Is easier to extend.
- Minimizes the impact of future changes.

**The objective is not just to make the software work. The objective is to build software that remains understandable, reliable, and extensible as it grows.**