# Migration Plan

Starting point (commit `c36452a`): Spring Boot 1.5.4, Spring Framework 4.3, Java 8, JUnit 4, Mockito 1.10, Thymeleaf 2, in-memory HSQLDB.

Target: Spring Boot 3.x on Java 17.

The migration is split into steps ordered by escalating risk. Each step is landed and approved on its own before the next begins, and every step is validated against the same two artifacts captured up front:

- `baseline/test-results.md` — 41 tests, 0 failures, 1 skipped (`CrashControllerTests` is `@Ignore`d).
- `baseline/http-snapshots/` — normalized responses for `/`, `/vets.html`, `/owners?lastName=`, `/owners/1`, produced by `baseline/snapshot.sh` so before/after runs can be diffed byte-for-byte.

Validation gate for every step: `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 mvn test` (JDK 17 from Step 2 on) matches the recorded test count and pass/fail/skip split, and re-running `baseline/snapshot.sh` into a scratch directory diffs clean against `baseline/http-snapshots/`.

### Snapshot gate caveats

`baseline/snapshot.sh` requires curl with support for following redirects and writing the response status via `-w '%{http_code}'`; it does not require `--fail-with-body`, so HTTP error responses are captured rather than aborting the run. Snapshot comparisons remain byte-for-byte, including whitespace. In Steps 3–4, any whitespace-only rendering differences caused by Thymeleaf 3 or `PathPatternParser` still require a line-by-line explanation; do not switch to whitespace-normalized diffing to make the gate pass. Snapshots embed pinned WebJars versions and host-relative resource URLs, so a dependency bump in Step 3 may produce version-only diffs; reviewers should explain those diffs rather than normalize them away.

---

## Step 1 — JUnit 4 → JUnit 5 (risk: LOW)

Test-scope only; no `src/main` change, so zero runtime impact. Confined to `pom.xml` test dependencies and the 10 test classes.

- `@RunWith(SpringRunner.class)` → `@ExtendWith(SpringExtension.class)`. Spring 4.3 has no `SpringExtension` of its own, so this comes from `org.springframework:spring-test-junit5`, the bridge artifact published for exactly this Boot 1.5 + Jupiter combination.
- `@RunWith(MockitoJUnitRunner.class)` → explicit `MockitoAnnotations.initMocks` in `@BeforeEach`. Boot 1.5 manages Mockito 1.10, which predates `mockito-junit-jupiter`; initializing mocks directly avoids pulling a new Mockito major version into this step and keeps the risk in the version bumps, not here.
- `org.junit.Test` → `org.junit.jupiter.api.Test`; `@Before` → `@BeforeEach`; `@Ignore` → `@Disabled` (`CrashControllerTests` must stay skipped, preserving the 1 skipped test).
- `@Test(expected = ParseException.class)` → `assertThrows`.
- `org.junit.Assert.assertEquals` → `org.junit.jupiter.api.Assertions.assertEquals`. AssertJ usage is unaffected.
- Surefire must be pinned to 2.22.x, the first version with native JUnit Platform support; the Boot 1.5 parent pins an older Surefire that ignores Jupiter tests entirely — a silently-green build with 0 tests run is the main failure mode to watch for here, which is why the gate compares test *counts*, not just build status.

Rollback: revert the commit. Nothing outside test scope is touched.

## Step 2 — Java 8 → 17 (risk: MEDIUM)

- `java.version` 1.8 → 17; refresh the build plugins that cannot parse a modern class file format (Surefire, Cobertura is likely dropped in favour of JaCoCo).
- Spring Framework 4.3 does not officially support Java 17 bytecode; expect reflection/CGLIB failures against `java.*` internals and strong encapsulation. If it cannot be made to run, Step 2 and Step 3 merge into one step on a single branch rather than weakening the gate.
- No source-level changes are expected beyond removing anything the newer compiler rejects.

Rollback: revert the commit; the runtime JDK is selected per environment, so a redeploy on JDK 8 restores the previous behaviour.

## Step 3 — Spring Boot 1.5 → 2.7 (risk: HIGH)

First step that changes production code and runtime behaviour.

- Parent 1.5.4 → 2.7.x, which brings Spring Framework 5.3, Hibernate 5.6, Thymeleaf 3, Mockito 4 and JUnit 5 as the managed default (Step 1 becomes native and the bridge artifact is removed).
- Configuration property renames (`spring.datasource.*`, `spring.jpa.*`), `WebMvcConfigurerAdapter` → `WebMvcConfigurer`, `CrudRepository` return types becoming `Optional`, Actuator endpoint paths moving under `/actuator`, and relaxed-binding changes in `application.properties`.
- Thymeleaf 2 → 3 changes template resolution and can alter rendered markup: this is the step where the HTTP snapshot diff is most likely to be non-empty, and any diff must be explained line by line rather than accepted.
- `spring-boot-starter-web` no longer pulls in the same defaults; the `wro4j` LESS pipeline and the WebJars version pins need re-verification.

Rollback: revert the merge commit. Because DB schema handling (`ddl-auto`) and Hibernate versions change, a rollback must be paired with re-running the previous schema scripts in any environment that is not in-memory HSQLDB.

## Step 4 — javax → jakarta, Boot 2.7 → 3.x (risk: HIGH)

- Package-level break: `javax.persistence`, `javax.validation` and `javax.servlet` → `jakarta.*` across entities, validators and any servlet-facing code. Mechanical but wide, and every third-party dependency must also ship a Jakarta-EE-10 build.
- Boot 3 requires Java 17 (already satisfied by Step 2), drops the remaining Boot 1.5-era configuration shims, and changes Hibernate to 6.x, whose SQL generation and naming strategy differ.
- Trailing-slash matching and `PathPatternParser` becoming the default alter URL handling; the snapshot suite exercises the affected owner/vet paths deliberately.

Rollback: revert the merge commit. Same schema caveat as Step 3, plus Hibernate 6 may have written schema that Hibernate 5 cannot read in a non-ephemeral database.

---

Only Step 1 is implemented in this migration series so far. Steps 2–4 are planned and await approval.
