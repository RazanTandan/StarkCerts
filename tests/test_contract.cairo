use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address, 
};
use stark_certs::interfaces::{
    ICertificateSystemDispatcher, ICertificateSystemDispatcherTrait,
    ICertificateSystemSafeDispatcher, ICertificateSystemSafeDispatcherTrait,
};

use stark_certs::certificates_system::CertificateSystem;
use starknet::ContractAddress;


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn USER_1() -> ContractAddress {
    'USER1'.try_into().unwrap()
}

fn USER_2() -> ContractAddress {
    'USER2'.try_into().unwrap()
}


#[test]
fn test_college_register_success() {
    let contract_address = deploy_contract("CertificateSystem");

    let dispatcher = ICertificateSystemDispatcher { contract_address };

    let college_id = dispatcher.register_college('PGS');
    assert!(college_id == 1, "Expected first college ID to be 1");
}

#[test]
fn test_college_register_multiple_different_addresses() {
    let contract_address = deploy_contract("CertificateSystem");
    let dispatcher = ICertificateSystemDispatcher { contract_address };

    let college_id = dispatcher.register_college('PGS');
    assert!(college_id == 1, "Expected first college ID to be 1");

    start_cheat_caller_address(contract_address, USER_1());
    let college_id_2 = dispatcher.register_college('KIG');
    assert!(college_id_2 == 2, "Expected second college ID to be 2");
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, USER_2());
    let college_id_3 = dispatcher.register_college('IGS');
    assert!(college_id_3 == 3, "Expected third college ID to be 3");
    stop_cheat_caller_address(contract_address);

    let college_count = dispatcher.get_college_count();
    assert!(college_count == 3, "Expected total college count to be 3");
}

#[test]
fn test_issue_certificate_success() {
    let contract_address = deploy_contract("CertificateSystem");
    let dispatcher = ICertificateSystemDispatcher { contract_address };

    start_cheat_caller_address(contract_address, USER_1());
    let college_id = dispatcher.register_college('KIG');
    assert!(college_id == 1, "Expected second college ID to be 1");

    let certi_id = dispatcher.issue_certificate(USER_2(), 'Bachelor in Arts');
    assert!(certi_id == 1, "Expected Certi ID to be 1");
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_full_workflow() {
    let contract_address = deploy_contract("CertificateSystem");
    let dispatcher = ICertificateSystemDispatcher { contract_address };

    // Register College
    let college_id = dispatcher.register_college('PGS');
    assert!(college_id == 1, "College registration failed: expected ID 1");

    // Issue Cert
    let certi_id = dispatcher.issue_certificate(USER_1(), 'Bachelor in Arts');
    assert!(certi_id == 1, "College registration failed: expected ID 1");

    // Verify Cert
    let bool_value = dispatcher.verify_certificate(certi_id);
    assert!(bool_value, "Certificate verification failed: invalid status");

    // Getting student crets
    let certi_array = dispatcher.get_student_certificates(USER_1());
    assert!(*certi_array[0] == 1, "Student certificate lookup failed: incorrect ID");
}

#[test]
fn test_college_registered_event() {
    let contract_address = deploy_contract("CertificateSystem");
    let dispatcher = ICertificateSystemDispatcher { contract_address };
    let mut spy = spy_events();

    // Register College
    start_cheat_caller_address(contract_address, USER_1());
    let college_id = dispatcher.register_college('PGS');

    stop_cheat_caller_address(contract_address);

    // Check the event was emitted
    spy.assert_emitted(
        @array![
            (
                contract_address,
                CertificateSystem::Event::CollegeRegistered(
                    CertificateSystem::CollegeRegistered { 
                        college_id, 
                        name: 'PGS', 
                        admin: USER_1() 
                    }
                )
            )
        ]
    );
}




#[test]
fn test_certi_issued_event() {
    let contract_address = deploy_contract("CertificateSystem");
    let dispatcher = ICertificateSystemDispatcher { contract_address };
    let mut spy = spy_events();

    // Register College
    start_cheat_caller_address(contract_address, USER_1());
    let college_id = dispatcher.register_college('PGS');
    let degree = 'Bachelor in Arts';

    let cert_id = dispatcher.issue_certificate(USER_2(), degree);
    stop_cheat_caller_address(contract_address);

    // Check the event was emitted
    spy.assert_emitted(
        @array![
            (
                contract_address,
                CertificateSystem::Event::CertificateIssued(
                    CertificateSystem::CertificateIssued { 
                        cert_id, 
                        student: USER_2(),
                        college_id, 
                        degree,
                    }
                )
            )
        ]
    );
}
