*** Settings ***
Documentation       Test Idempotentności Usunięcia — DELETE powinien być idempotentny
Library             RequestsLibrary
Library             Collections

Suite Setup         Create Session    epc    http://127.0.0.1:8000
Suite Teardown      Delete All Sessions
Test Setup          Reset Simulator

*** Test Cases ***
DELETE Idempotency — Second Delete Should Not Return 500
    [Documentation]    Pierwsze DELETE usuwa UE. Drugie DELETE tego samego UE
    ...                powinno zwrócić 404 (lub 200), nigdy 500.

    Attach UE With ID    10

    ${first_resp}=    DELETE On Session    epc    /ues/10    expected_status=any
    Should Be Equal As Integers    ${first_resp.status_code}    200

    Sleep    1s

    ${second_resp}=    DELETE On Session    epc    /ues/10    expected_status=any
    Should Be True    ${second_resp.status_code} != 500
    ...    msg=Błąd! Drugie DELETE zwróciło 500 — aplikacja nie jest idempotentna!
    Log    Drugie DELETE zwróciło: ${second_resp.status_code}    level=WARN

    *** Keywords ***
Reset Simulator
    [Documentation]    Przywraca symulator do stanu początkowego
    POST On Session    epc    /reset

Attach UE With ID
    [Documentation]    Dołącza UE o podanym ID do sieci
    [Arguments]    ${ue_id}
    ${body}=    Create Dictionary    ue_id=${ue_id}
    POST On Session    epc    /ues    json=${body}    expected_status=200