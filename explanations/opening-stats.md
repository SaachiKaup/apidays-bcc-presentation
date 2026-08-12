# Opening: Why Backward Compatibility Matters

## The opening question

> If changing a web API response can make more than one in three mobile applications fail, how do we know which consumers are safe before we release?

## Evidence

An earlier study of 43 mobile applications found that, in more than 30% of the cases, the mobile application failed when the web API response changed.

Source: [To react, or not to react: Patterns of reaction to API deprecation](https://link.springer.com/article/10.1007/s10664-019-09713-w)

A newer 2024 study of 681 open-source Android applications found:

- On average, each application had two API field compatibility issues in each release snapshot.
- Method-level API analysis can miss many compatibility issues caused by changes to API fields.
- Fixing an API field compatibility issue took three and a half months on average from introduction to resolution.

Source: [An empirical study on compatibility issues in Android API field evolution](https://doi.org/10.1016/j.infsof.2024.107530)

## Suggested narration

> Backward compatibility is not a theoretical concern. Earlier research found that changing a web API response caused mobile applications to fail in more than 30% of observed cases. More recent research found an average of two API field compatibility issues per Android application, with fixes taking about three and a half months.

> The problem is also easy to miss: checking only API methods does not catch every field-level compatibility issue. So before we talk about a release, let’s ask a simple question: can we detect these breaks while the contract is still being changed?

This leads into the demo: one enterprise release, several specification types, and one backward compatibility check before consumers discover the problem.

## Important distinction

The two studies measure different things. The older study measured consumer failures after web API response changes. The newer study measured API field compatibility issues and the time needed to fix them. They should be presented as complementary evidence, not as one combined statistic.
