@api/v1
Feature: Release entitlements relationship

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "403"

  Scenario: Admin retrieves the entitlements for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "entitlements"

  Scenario: Product retrieves the entitlements for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "entitlements"

  Scenario: Admin retrieves an entitlement for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Product retrieves an entitlement for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the JSON response should be a "entitlement"

  Scenario: Product retrieves the entitlements for a release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the entitlements for a release of a different product
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the entitlements for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the entitlements for a release they don't have a license for
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the entitlements for a release they do have a license for
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the entitlements for a release of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "401"

  Scenario: License attempts to retrieve an entitlement for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "403"

  Scenario: User attempts to retrieve an entitlement for a release they do have a license for
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "403"