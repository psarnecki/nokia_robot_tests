*** Settings *** 
Documentation   Boundary Value Analysis
Library         RequestsLibrary
Library         Collections

Suite Setup     Create Session    api    http://127.0.0.1:8001    #Przed testami tworzymy sesje HTTP
Suite Teardown  Delete All Sessions    #Po testach sprzątamy sesje
Test Setup      Reset Simulator    #Przed testem reset
*** Variables ***

*** Test Cases ***
BVA - UE ID Out Of Range Should Return 422
    [Documentation] ue_id=101 jest poza zakresem 0-100. API powinno zwrócić 422.
    ${respo}= Post On Session    eps    /ues    json={"ue_id": 101}    expected_status=any    #nie rzucaj wyjatkiem, daj mi odpowiedz
    Should Be Equal As Integers    ${respo.status_code}    422

BVA - Bearer ID Out Of Range Should Return 422
    [Documentation] bearer_id=10 jest poza zakresem 0-9. API powinno zwrócić 422.
    ${respo}= Post On Session    eps    /ues/1/bearers     json={"bearer_id": 10}    expected_status=any
    Should Be Equal As Integers    ${respo.status_code}    422

BVA — Invalid Protocol Should Return 422
    [Documentation]    protocol="http" jest nieprawidłowy (tylko tcp/udp). API powinno zwrócić 422.
    Attach UE With ID    1
    ${resp}=    POST On Session    epc    /ues/1/bearers/9/traffic
    ...    json={"protocol": "http", "Mbps": 10}    expected_status=any
    Should Be Equal As Integers    ${resp.status_code}    422

*** Keywords ***
Reset Simulator
    [Documentation] Przywraca Symulator do stanu poczatkowego
    Post On Session    api    /reset

Attach UE With ID    
#keyword z jednym argumentem ${ue_id}, żebyśmy nie pisali tego samego kodu w każdym teście
    [Documentation]    Dolacza UE o podanym ID do sieci
    [Aruguments]    ${ue_id}
    ${body}=   Create Dictionary    ue_id=${ue_id}
    Post On Session    eps    /ues    json=${body}    expected_status=200



