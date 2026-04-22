*** Settings ***
Library    RequestsLibrary
Library    Collections
Suite Setup    Create Session    epc    http://127.0.0.1:8000
Suite Teardown    Delete All Sessions
Test Setup    Reset Simulator

*** Test Cases ***
Include Details On Empty Network — Should Not Crash
    [Documentation]    Sprawdza, czy GET /ues/stats?include_details=true nie zwraca 500 gdy sieć jest pusta (brak podłączonych UE).
    ${resp}=    Get Stats With Include Details
    Status Should Not Be Server Error    ${resp}

*** Keywords ***
Reset Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    POST On Session    epc    /reset

Get Stats With Include Details
    [Documentation]    Wysyła GET /ues/stats z parametrem include_details=true
    ${resp}=    GET On Session    epc    /ues/stats
    ...    params=include_details=true    expected_status=any
    RETURN    ${resp}

Status Should Not Be Server Error
    [Documentation]    Weryfikuje, czy odpowiedź nie jest błędem serwera (5xx)
    [Arguments]    ${resp}
    Should Be True    ${resp.status_code} < 500
    Log    Given status code: ${resp.status_code} Body: ${resp.text}    level=WARN