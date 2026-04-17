# Section: sections-happy.md
# Loaded ONLY when NEG_ONLY=false (the default).
# Contains document Sections 3, 8, and 10.
# Do NOT load this file when NEG_ONLY=true.

---

## Section 3: Happy Path Scenarios — minimum 10

Gherkin header:
```
| Scenario | Priority | Gherkin (Given/When/Then) | Test Data Required |
```

Tab-separated header (--no-gherkin):
```
Scenario	Priority	CommonSteps Sequence	Test Data Required
```

Cover the primary success flows. Every scenario must be tagged with a priority.

---

## Section 8: Cross-Platform / Compatibility Testing

Gherkin header:
```
| Scenario | Priority | Platforms/Environments Tested | Gherkin (Given/When/Then) |
```

Tab-separated header (--no-gherkin):
```
Scenario	Priority	Platforms/Environments Tested	Validation Points
```

Use platforms from `.test-gen.json` config if present (default: iOS/Android).
Cover: latest and N-1 OS versions, fix version builds, screen sizes, network conditions
(WiFi, 4G, degraded).

---

## Section 10: Exploratory Test Charter

```
Mission:
[One paragraph — exploration goal, system under test, key risk areas]

Areas to Investigate:
- [area 1]
- [area 2]
- [area 3]
- [area 4]
- [area 5]
```

Minimum 5 areas. Focus on risk, edge behaviour, and integration points not covered by scripted tests.
