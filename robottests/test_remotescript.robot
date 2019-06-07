# Copyright (C) 2019, Nokia

*** Settings ***

Library    Process
Library    OperatingSystem
Library    Collections
Library    crl.remotescript.RemoteScript    WITH NAME    RemoteScript

Test Setup    Better Set RemoteScript Targets
Suite Teardown  Run Process  rm -rf /tmp/pdrobot-remotescript  shell=${True}
Force Tags     bug-crl-97

*** Variables ***
${TARGET_FILE}=  foo.sh
${TESTFILESIZE}=    1000000

*** Keywords ***
Remote Test Setup
    Better Set RemoteScript Targets

Set RemoteScript Sudo Target
    RemoteScript.Set Target    host=${HOST1.host}
    ...                        username=${HOST1.user}
    ...                        password=${HOST1.password}
    RemoteScript.Set Target Property    default    su password    ${HOST1.password}
    RemoteScript.Set Target Property    default    su username    root
    RemoteScript.Set Target Property    default    use sudo user    ${TRUE}

Better Set RemoteScript Targets
    [Arguments]     ${host}=${HOST1.host}
    ...             ${username}=${HOST1.user}
    ...             ${password}=${HOST1.password}
    ...             ${target}=default
    RemoteScript.Set Target     host=${host}
    ...                         username=${username}
    ...                         password=${password}
    ...                         name=${target}
Workaround Create Directory In Target
    [Arguments]  ${target}=default  ${dir}=/tmp/${target}
    ${ret1}=    Execute Command In Target   mkdir -p ${dir}  target=${target}
    Should Be Equal As Integers     ${ret1.status}   0   ${ret1}

Create File In Target
    [Arguments]  ${target}=default  ${dir}=/tmp/${target}  ${file}=${TARGET_FILE}
    ${ret2}=    Execute Command In Target   touch ${dir}/${file}
    Should Be Equal As Integers     ${ret2.status}  0   ${ret2}

RemoteScript Copy Directory To Target
    Run Process     mkdir -p scripts  shell=${True}
    ${cpresult}=      RemoteScript.Copy Directory To Target
    ...     scripts
    ...     /tmp/my-robot-tc/scripts/
    Should Be Equal As Integers     ${cpresult.status}   0   ${cpresult}
    ${ret}=  Execute Command In Target   tar -cvzf target.tgz /tmp/my-robot-tc/scripts/
    Should Be Equal As Integers     ${ret.status}   0   ${ret}
    #Copy File From Target   source_file=target.tgz
    #Run Process     tar -xvzf target.tgz  shell=${True}
    #${result}=      Run Process     diff -r scripts /tmp/my-robot-tc/scripts/  shell=${True}
    #Should Be Equal As Integers     ${result.rc}    0   ${result}
    [Teardown]  RemoteScript.Execute Command In Target  rm -rf /tmp/my-robot-tc/scripts/ target.tgz
    Run Process     rm -rf scripts  shell=${True}

RemoteScript Execute Command In Target
    ${result}=     RemoteScript.Execute Command In Target  echo foo; echo bar>&2    timeout=10
    Should Be Equal     ${result.status}   0
    Should Be Equal     ${result.stdout}   foo
    Should Be Equal     ${result.stderr}   bar
    Should Be Equal     ${result.connection_ok}     True

RemoteScript Copy File To Target
    Run Process     touch  ./foo.sh
    Workaround Create Directory In Target
    ${ret2}=    Copy File To Target  source_file=./foo.sh  destination_dir=/tmp/target_dir
    Should Be Equal As Integers     ${ret2.status}   0   ${ret2}
    ${ret3}=    Execute Command In Target   stat /tmp/target_dir/foo.sh
    Should Be Equal As Integers     ${ret3.status}  0   ${ret3}
    [Teardown]  RemoteScript.Execute Command In Target  rm -r /tmp/target_dir
    Run Process     rm foo.sh  shell=${True}

RemoteScript Copy File From Target
    Workaround Create Directory In Target
    Create File In Target
    ${ret3}=    Copy File From Target   source_file=/tmp/default/foo.sh  destination=.
    Should Be Equal As Integers     ${ret3.status}  0   ${ret3}
    File Should Exist   path=foo.sh
    [Teardown]  Execute Command In Target  rm -rf /tmp/target_dir
    Run Process     rm foo.sh  shell=${True}

RemoteScript Create Directory In Target
    Workaround Create Directory In Target
    ${ret2}=    Execute Command In Target   stat /tmp/target_dir
    Should Be Equal As Integers     ${ret2.status}  0   ${ret2}
    [Teardown]  Execute Command In Target rm -r /tmp/target_dir

RemoteScript Remove Directory In Target
    Workaround Create Directory In Target
    ${ret2}=    Remove Directory In Target  path=/tmp/target_dir
    Should Be Equal As Integers     ${ret2.status}  0   ${ret2}
    ${ret3}=    Execute Command In Target   stat /tmp/target_dir
    Should Be Equal As Integers     ${ret3.status}  1   ${ret3}

RemoteScript Set Target With Sshkeyfile
    Set Target With Sshkeyfile  host=${HOST2.host}
    ...                         username=${HOST2.user}
    ...                         sshkeyfile=${HOST2.key}
    ...                         name=host2
    ${ret}=     Execute Command In Target   echo out    target=host2
    Should Be Equal As Integers     ${ret.status}   0   ${ret}

RemoteScript Get Target Properties
    ${ret}=    Get Target Properties  target=default
    Dictionary Should Contain Sub Dictionary     ${ret}   ${DEFAULT_TARGET}

RemoteScript Execute Script In Target
    Workaround Create Directory In Target
    ${out}=     Run Process  ls ${CURDIR}  shell=${True}
    Log  ${out.stdout}
    ${ret2}=    Copy File To Target  source_file=${CURDIR}/target_script.sh  destination_dir=/tmp/target_dir
    Should Be Equal As Integers     ${ret2.status}  0
    ${ret3}=     Execute Script In Target    file=/tmp/target_dir/target_script.sh
    Should Be Equal As Integers     ${ret3.status}  0
    [Teardown]  Execute Command In Target  rm -r /tmp/target_dir

RemoteScript Execute Background Command In Target
    Execute Background Command In Target    command=echo Hello;echo World!>&2  target=default  exec_id=bg1
    Execute Background Command In Target    command=echo Hello;echo World!>&2  target=default  exec_id=bg2
    Execute Background Command In Target    command=echo Hello;echo World!>&2  target=default  exec_id=bg3
    ${result_1}=    Wait Background Execution  bg1
    ${result_2}=    Wait Background Execution  bg2
    ${result_3}=    Wait Background Execution  bg3
    Should Be Equal As Integers     ${result_1.status}     0
    Should Be Equal As Integers     ${result_2.status}     0
    Should Be Equal As Integers     ${result_3.status}     0
    Should Be Equal      ${result_1.stdout}   Hello
    Should Be Equal      ${result_2.stdout}   Hello
    Should Be Equal      ${result_3.stdout}   Hello
    Should Be Equal      ${result_1.stderr}   World!
    Should Be Equal      ${result_2.stderr}   World!
    Should Be Equal      ${result_3.stderr}   World!

RemoteScript Execute Background Script In Target
    Workaround Create Directory In Target
    ${out}=     Run Process  ls ${CURDIR}  shell=${True}
    Log  ${out.stdout}
    ${ret2}=    Copy File To Target  source_file=${CURDIR}/target_script.sh  destination_dir=/tmp/target_dir
    Should Be Equal As Integers     ${ret2.status}  0
    Execute Background Script In Target  file=/tmp/target_dir/target_script.sh  target=default  exec_id=bg1
    ${result_bg1}=  Wait Background Execution   exec_id=bg1
    Log  ${result_bg1}
    Should Be Equal As Integers     ${result_bg1.status}   0
    [Teardown]  Execute Command In Target   rm -r /tmp/target_dir

RemoteScript Copy File Between Targets
    RemoteScript Set Target With Sshkeyfile
    Workaround Create Directory In Target
    Workaround Create Directory In Target  target=host2
    Create File In Target
    ${ret}=     Copy File Between Targets
    ...         from_target=default
    ...         source_file=/tmp/default/${TARGET_FILE}
    ...         to_target=host2
    ...         destination_dir=/tmp/host2
    Should Be Equal As Integers     ${ret.status}   0
    Log  ${ret}

RemoteScript Kill Background Execution
    Execute Background Command In Target    command=echo Hello; sleep 3   target=default  exec_id=bg1
    Sleep  1
    Kill Background Execution  exec_id=bg1
    ${ret}=     Wait Background Execution  exec_id=bg1
    Log  ${ret}

RemoteScript Set Target Property
    RemoteScript Set Target With Sshkeyfile
    ${prop}=    Get Target Properties  target=default
    FOR     ${key}  IN  @{prop.keys()}
        Set Target Property  target_name=host2  property_name=${key}  property_value=${prop["${key}"]}
    END
    ${tprop}=   Get Target Properties  target=host2
    Log  ${prop}
    Log  ${tprop}
    Dictionary Should Contain Sub Dictionary  ${prop}  ${tprop}

RemoteScript Set Default Target Property
    RemoteScript Set Target With Sshkeyfile
    ${prop}=    Get Target Properties   target=default
    FOR     ${key}  IN  @{prop.keys()}
        Set Default Target Property  property_name=${key}    property_value=${prop["${key}"]}
    END
    ${tprop}=   Get Target Properties  target=host2
    Log  ${prop}
    Log  ${tprop}
    Dictionary Should Contain Sub Dictionary  ${prop}   ${tprop}

*** Test Cases ***

#Test Echo With Su
#    ${ret}=    RemoteScript.Execute Command In Target    echo out  timeout=5
#    Should Be Equal    ${ret.status}   0
#    Should Be Equal    ${ret.stdout}   out


Test Copy Directory To Target
    [Tags]  skip      #TODO: See issue [#10]
    RemoteScript Copy Directory To Target

Test Create Directory In Target
    [Tags]  skip     #TODO: See issue [#8]
    RemoteScript Create Directory In Target

Test Execute Command In Target
    RemoteScript Execute Command In Target

Test Copy File To Target
    Remotescript Copy File To Target

Test Copy File From Target
    Remotescript Copy File From Target

Test Remove Directory In Target
    RemoteScript Remove Directory In Target

Test Set Target With Sshkeyfile
    RemoteScript Set Target With Sshkeyfile

Test Get Target Properties
    RemoteScript Get Target Properties

Test Execute Script In Target
    RemoteScript Execute Script In Target

Test Execute Background Command In Target
    RemoteScript Execute Background Command In Target

Test Execute Background Script In Target
    RemoteScript Execute Background Script In Target

Test RemoteScript Copy File Between Targets
    RemoteScript Copy File Between Targets

Test RemoteScript Kill Background Execution
    [Tags]  skip    #TODO: See issue [#11]
    RemoteScript Kill Background Execution

Test RemoteScript Set Target Property
    RemoteScript Set Target Property

Test RemoteScript Set Default Target Property
    RemoteScript Set Default Target Property
