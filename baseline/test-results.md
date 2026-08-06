# Test Baseline

- Commit: `c36452a2c34443ae26b4ecbba4f149906af14717`
- Command: `JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 mvn test`
- Result: BUILD SUCCESS
- Total tests: 41
- Passed: 40
- Failed: 0
- Errors: 0
- Skipped: 1
- Java: OpenJDK 1.8.0_492 (64-bit)
- Maven: Apache Maven 3.6.3
- Spring Boot: 1.5.4.RELEASE
- Project version: 1.5.1

## Per-test-class breakdown

| Test class | Run | Failures | Errors | Skipped |
|---|---:|---:|---:|---:|
| `org.springframework.samples.petclinic.service.ClinicServiceTests` | 11 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.system.CrashControllerTests` | 1 | 0 | 0 | 1 |
| `org.springframework.samples.petclinic.system.ProductionConfigurationTests` | 1 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.owner.PetTypeFormatterTests` | 3 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.owner.OwnerControllerTests` | 11 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.owner.VisitControllerTests` | 3 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.owner.PetControllerTests` | 6 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.vet.VetControllerTests` | 3 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.vet.VetTests` | 1 | 0 | 0 | 0 |
| `org.springframework.samples.petclinic.model.ValidatorTests` | 1 | 0 | 0 | 0 |

## Raw Surefire summary lines

```text
Running org.springframework.samples.petclinic.service.ClinicServiceTests
Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.649 sec - in org.springframework.samples.petclinic.service.ClinicServiceTests
Running org.springframework.samples.petclinic.system.CrashControllerTests
Tests run: 1, Failures: 0, Errors: 0, Skipped: 1, Time elapsed: 0 sec - in org.springframework.samples.petclinic.system.CrashControllerTests
Running org.springframework.samples.petclinic.system.ProductionConfigurationTests
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.571 sec - in org.springframework.samples.petclinic.system.ProductionConfigurationTests
Running org.springframework.samples.petclinic.owner.PetTypeFormatterTests
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.05 sec - in org.springframework.samples.petclinic.owner.PetTypeFormatterTests
Running org.springframework.samples.petclinic.owner.OwnerControllerTests
Tests run: 11, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.624 sec - in org.springframework.samples.petclinic.owner.OwnerControllerTests
Running org.springframework.samples.petclinic.owner.VisitControllerTests
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.224 sec - in org.springframework.samples.petclinic.owner.VisitControllerTests
Running org.springframework.samples.petclinic.owner.PetControllerTests
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.224 sec - in org.springframework.samples.petclinic.owner.PetControllerTests
Running org.springframework.samples.petclinic.vet.VetControllerTests
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.304 sec - in org.springframework.samples.petclinic.vet.VetControllerTests
Running org.springframework.samples.petclinic.vet.VetTests
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0 sec - in org.springframework.samples.petclinic.vet.VetTests
Running org.springframework.samples.petclinic.model.ValidatorTests
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.004 sec - in org.springframework.samples.petclinic.model.ValidatorTests

Results :
Tests run: 41, Failures: 0, Errors: 0, Skipped: 1
```
