use candid::parser::test::HostAssert::Decode;
use candid::{CandidType, Decode, Encode};
use ic_agent::agent::http_transport::ReqwestHttpReplicaV2Transport;
use ic_agent::Agent;
use ic_types::Principal;
use serde::Deserialize;

#[derive(CandidType, Debug, Deserialize)]
struct Token {
    e8s: u64,
}

#[derive(Debug, CandidType, Deserialize)]
struct Status {
    account_identifier: Vec<u8>,
    icp_balance: Token,
    cycle_ai: Vec<u8>,
    cycle_balance: u128,
}

#[tokio::main]
async fn main() {
    let canister_id =
        Principal::from_text("5p5z6-piaaa-aaaak-qadda-cai").expect("get pricipal failed");
    //get_info(&canister_id).await;
    println!("before top up");
    get_cycle_balance(&canister_id).await;
    top_up(&canister_id).await;
    println!("after top up");
    get_cycle_balance(&canister_id).await;
}

async fn get_info(canister_id: &Principal) -> () {
    let url = "https://ic0.app".to_string();
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let agent = Agent::builder()
        .with_transport(transport)
        .build()
        .expect("build agent error");
    let waiter = garcon::Delay::builder()
        .throttle(std::time::Duration::from_millis(500))
        .timeout(std::time::Duration::from_secs(60 * 5))
        .build();
    let _ = agent.fetch_root_key();
    let response = agent
        .update(canister_id, "info")
        .with_arg(Encode!().unwrap())
        .call_and_wait(waiter)
        .await;
    match response {
        Ok(response) => {
            let res = Decode!(&response, Status).expect("decode response failed");
            println!(
                "response : \n \
                account identifier : {}\n\
                icp balance: {:?}\n\
                cycle account identifier : {} \n\
                cycle balance : {}",
                hex::encode(res.account_identifier),
                res.icp_balance,
                hex::encode(res.cycle_ai),
                res.cycle_balance
            );
        }
        Err(e) => {
            println!("{:?}", e)
        }
    }
}

async fn top_up(canister_id: &Principal) -> () {
    let url = "https://ic0.app".to_string();
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let agent = Agent::builder()
        .with_transport(transport)
        .build()
        .expect("build agent error");
    let waiter = garcon::Delay::builder()
        .throttle(std::time::Duration::from_millis(500))
        .timeout(std::time::Duration::from_secs(60 * 5))
        .build();
    let _ = agent.fetch_root_key();
    let response = agent
        .update(canister_id, "top_up")
        .with_arg(Encode!().unwrap())
        .call_and_wait(waiter)
        .await;
    match response {
        Ok(response) => {
            let res = Decode!(&response, String).expect("decode response failed");
            println!("{}", res);
        }
        Err(e) => {
            println!("{:?}", e)
        }
    }
}

async fn get_cycle_balance(canister_id: &Principal) -> () {
    let url = "https://ic0.app".to_string();
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let agent = Agent::builder()
        .with_transport(transport)
        .build()
        .expect("build agent error");
    let _ = agent.fetch_root_key();
    let response = agent
        .query(canister_id, "cycle_balance")
        .with_arg(Encode!().unwrap())
        .call()
        .await
        .expect("get cycle balance failed");
    println!(
        "cycle balance : {}",
        Decode!(&response, u128).expect("decode response failed")
    )
}

async fn get_aid(canister_id: &Principal) -> () {
    let url = "https://ic0.app".to_string();
    let transport = ReqwestHttpReplicaV2Transport::create(url).unwrap();
    let agent = Agent::builder()
        .with_transport(transport)
        .build()
        .expect("build agent error");
    let _ = agent.fetch_root_key();
    let response = agent
        .query(canister_id, "aid")
        .with_arg(Encode!().unwrap())
        .call()
        .await
        .expect("get cycle balance failed");
    let response = Decode!(&response, String).expect("decode response failed");
    println!("{}", response)
}

async fn test() -> () {
    let canister_id = Principal::from_text("aaaaa-aa").unwrap();
}
