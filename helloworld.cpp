#include<iostream>
using namespace std;



struct DownStreamGLHead {
public:
        //uint64_t getSendTimestamp() { return ntohll(sendTimestamp); }

        //uint32_t getFrameCount() { return ntohl(m_frameCount); }

        //uint32_t getPid() { return ntohl(this->m_pid); }

        //uint32_t getTid() { return ntohl(this->m_tid); }

private:

        uint32_t compressTypeAndPlainDataLength = 0;
        uint32_t m_pid = 0;
        uint32_t m_tid = 0;
        uint32_t m_frameCount = 0;
        uint64_t sendTimestamp = 0;
};


int main(){

std::pair<uint8_t *, uint32_t> packetPair;
uint8_t *payload = packetPair.first;
uint32_t payloadSize = packetPair.second;

auto downStreamHead = static_cast<DownStreamGLHead *>(static_cast<void *>(payload));

cout<<"Hello, Linux!"<<endl;
return 0;
}

