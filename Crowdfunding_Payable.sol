pragma solidity ^0.4.17;

contract Crowdfunding {
    
    // Variables: 
    address private npo;
    address[] private Receiver; 
    uint private Target;
    uint private target;    
    address[] private donor_list;
    mapping (address => uint) private donors;
    uint private DonatedAmount; 
    uint private Phase1_Amount;
    uint private Phase2_Amount;
    uint private NPO_amount;    
    uint private phase1_status;
    uint private phase2_status;
    string feedback1;
    string feedback2;   
    string private fundingstatus; 
    uint private refund_total;
    uint private refund;    
    
    constructor(address receiver) public {
        npo = msg.sender;
        Receiver.push(receiver);
        
    }
    
    // Modefiers:
    modifier restricted() {
        require(msg.sender == npo);
        _;
    }
    
    modifier donorsonly(){
        require(donors[msg.sender]>= 0);
        _;
    }    

    modifier receiversonly(){
        require(msg.sender == Receiver[0]);
        _;
    }
    
    // Transaction functions:
    
    function Set_Target_ether(uint amount) public restricted{
        Target= amount*(10**18);
        target=amount;
    } 
    function Donated_Amount() payable public {
        require(msg.value > 0.01 ether);
        require(phase1_status!=1 && phase2_status!=1);
        donor_list.push(msg.sender);
        donors[msg.sender] += msg.value;
        DonatedAmount += msg.value;
        if (DonatedAmount>=Target*60/100 && NPO_amount == 0){
            Phase1_Amount=Target*50/100;
            NPO_amount = Phase1_Amount;
            npo.transfer(NPO_amount);
        }else if (phase1_status == 2 && DonatedAmount>=Target ){
            Phase2_Amount=DonatedAmount - Phase1_Amount;
            NPO_amount = Phase1_Amount + Phase2_Amount;
            npo.transfer(Phase2_Amount);
        }
        Funding_Status();
    }    
    function Phase1_Qualified (uint st1) public receiversonly{
        require(Phase1_Amount>0);
        phase1_status=st1;
    }
    function Phase1_Feedback(string f1) public receiversonly{
        require(phase1_status>=0);
        feedback1=f1;    
        Funding_Status();
    }
    function Phase2_Qualified (uint st2) public receiversonly{
        require(bytes(feedback1).length >0 && Phase2_Amount>0);
        phase2_status=st2;
    }
    function Phase2_Feedback(string f2) public receiversonly{
        require(phase2_status>=0);
        feedback2=f2;
        Funding_Status();
    }
    function Funding_Status() private{
        if (Phase1_Amount==0){
            fundingstatus= "Phase1 Still Funding";
        }
        else if (phase1_status<1){ 
            fundingstatus="Transfered Phase 1 to NPO, waiting receiver's feedback";
        }
        else if (phase1_status == 1 ){
            fundingstatus="Received Phase1 supplies, not qualified. Phase1 failed";
        }
        else if (Phase2_Amount ==0){
            fundingstatus= "Received Phase1 supplies, qualified. Please check feedback; Phase2 is still funding";
        }
        else if (phase2_status<1){
            fundingstatus="Transfered Phase2 to NPO, waiting receiver's feedback";
        }
        else if (phase2_status == 1){
            fundingstatus="Received Phase2 supplies, not qualified. Phase2 failed";
        }
        else{
            fundingstatus="Received Phase2 supplies, qualified. Please check feedback";
        }
    }
    function Request_Refund()  payable public{
        require(phase1_status == 1);
        refund=donors[msg.sender]*(DonatedAmount - NPO_amount)/DonatedAmount;
        msg.sender.transfer(refund);
        refund_total+=refund;
        donors[msg.sender]=0;
    }
        
    // Call functions:    
    function Get_Target_ether() public view returns(uint){
        return target;
    } 
    function show_npo()  public view returns(address){
        return npo;
    }
    function show_receiver() public view returns(address){
        return Receiver[0];
    }    
    function Show_DonorsDonation() public view returns (uint){
        return donors[msg.sender];
    }
    function show_donors() public view returns(address[]){
        return donor_list;
    }
    function Get_Donation() public view returns(uint){
        return DonatedAmount;
    }
    function Get_current() public view returns(uint){
        return address(this).balance;
    }
    function Get_NPO_Account() public view returns(uint){
        return NPO_amount;
    }
    function Get_Status() public view returns(string){
        return fundingstatus;
    }
    function Get_Feedback1() public view returns(string){
        return feedback1;
    }
    function Get_Feedback2() public view returns(string){
        return feedback2;
    }
    function Show_personal_Refund() public view returns(uint){
        return refund;
    }
    function Show_total_Refund() public view returns(uint){
        return refund_total;
    }
    function getBalance() public view returns (uint) {
        return address(this).balance;    
    }
}    
