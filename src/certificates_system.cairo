use crate::interfaces::*;

#[starknet::contract]
pub mod CertificateSystem {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::*;
    use super::{College, Certificate, ICertificateSystem};

    #[storage]
    struct Storage {
        // College storage
        colleges: Map<u32, College>,
        college_admins: Map<ContractAddress, u32>, // admin -> college_id
        college_count: u32,
        
        // Certificate storage
        certificates: Map<u256, Certificate>,
        student_certificates: Map<(ContractAddress, u32), u256>, // (student, index) -> cert_id
        student_cert_count: Map<ContractAddress, u32>,
        certificate_count: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CollegeRegistered: CollegeRegistered,
        CertificateIssued: CertificateIssued,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CollegeRegistered {
        #[key]
        pub college_id: u32,
        pub name: felt252,
        pub admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CertificateIssued {
        #[key]
        pub cert_id: u256,
        pub student: ContractAddress,
        pub college_id: u32,
        pub degree: felt252,
    }

    #[abi(embed_v0)]
    impl CertificateSystemImpl of ICertificateSystem<ContractState> {
        fn register_college(ref self: ContractState, name: felt252) -> u32 {
            let caller = get_caller_address(); 

            // Check if caller already has a college 
            let existing_college_id = self.college_admins.entry(caller).read(); 
            assert(existing_college_id == 0, 'Already registered');

            // Add new College
            let college_id = self.college_count.read() + 1; 
            let college = College { 
                id: college_id, 
                name, 
                admin: caller, 
                is_active: true, 
            }; 

            // Store college data
            self.colleges.entry(college_id).write(college); 
            self.college_admins.entry(caller).write(college_id); 
            self.college_count.write(college_id); 

            //  Emit CollegeRegistered event
            self.emit(CollegeRegistered { college_id, name, admin: caller }); 

            college_id
        }

        fn get_college(self: @ContractState, college_id: u32) -> College{
            let college = self.colleges.entry(college_id).read(); 
            assert(college.id != 0, 'College not found');
            college
        }

        fn issue_certificate(ref self: ContractState, student: ContractAddress, degree: felt252) -> u256 {
            let caller = get_caller_address(); 

            // Check if caller is a registerd college admin
            let college_id = self.college_admins.entry(caller).read(); 
            assert(college_id != 0, 'Not a college admin');

            // Check if college is active
            let college = self.colleges.entry(college_id).read();
            assert(college.is_active, 'College not active'); 


            // Create Certificate
            let certificate_id = self.certificate_count.read() + 1; 
            let certificate = Certificate { 
                id: certificate_id, 
                student, 
                college_id, 
                degree, 
                issue_date: get_block_timestamp(), 
                is_valid: true, 
            };

            // Store Certificate
            self.certificates.entry(certificate_id).write(certificate);
            self.certificate_count.write(certificate_id); 

            // Add to Student's certificate list
            let student_cert_index = self.student_cert_count.entry(student).read();
            self.student_certificates.entry((student, student_cert_index)).write(certificate_id);
            self.student_cert_count.entry(student).write(student_cert_index + 1);
            
            // Emit events
            self.emit(CertificateIssued { cert_id: certificate_id, student, college_id, degree});

            certificate_id 
        }


        fn get_certificate(self: @ContractState, cert_id: u256) -> Certificate {
            let certificate = self.certificates.entry(cert_id).read();
            assert(certificate.id != 0, 'Certificate not found');

            certificate
        }

        fn verify_certificate(self: @ContractState, cert_id: u256) -> bool {
            let certificate = self.certificates.entry(cert_id).read();
            if certificate.id == 0 { 
                return false;
            }

            // Check if college is active and certicate valid or not
            let college = self.colleges.entry(certificate.college_id).read(); 
            certificate.is_valid && college.is_active
        }

        fn get_student_certificates(self: @ContractState, student: ContractAddress) -> Array<u256> {
            let mut certificates = ArrayTrait::new();
            let cert_count = self.student_cert_count.entry(student).read();

            let mut i = 0;
            while i != cert_count { 
                let cert_id = self.student_certificates.entry((student, i)).read();
                certificates.append(cert_id);
                i = i + 1;
            }; 

            certificates
        }

        fn get_college_count(self: @ContractState) -> u32 {
            self.college_count.read()
        }

        fn get_certificate_count(self: @ContractState) -> u256 {
            self.certificate_count.read()
        }
    
    }
}