#define NOMINMAX
#include <string>
#include <cassert>
#include <iostream>
namespace localio { inline void write_atomic(const std::wstring&,const std::string&){} }
#include "party_input.hpp"
int main(){
 using namespace partyinput;
 Calibration centers[4]{};centers[3]={{0,0,-14521,0},{2500,2500}};
 SingleInput filter;
 assert(!filter.accept("PBZSINGLE1 old 2","new"));
 for(auto bad:{"", "PBZSINGLE1 new -1", "PBZSINGLE1 new 5", "PBZSINGLE1 new 2 extra", "PBZSINGLE1 new 22"})assert(!filter.accept(bad,"new"));
 assert(!filter.enabled);
 assert(filter.accept("PBZSINGLE1 new 2\n","new"));
 assert(!filter.accept("PBZSINGLE1 new 4","new") && filter.device==2);
 XINPUT_STATE s{};s.Gamepad.sThumbRX=-14521;s.Gamepad.wButtons=XINPUT_GAMEPAD_A;s.Gamepad.bRightTrigger=255;
 assert(filter.transform(3,0,&s,true,centers)==0 && s.Gamepad.sThumbRX==0 && s.Gamepad.wButtons==0 && s.Gamepad.bRightTrigger==0);
 for(int i=0;i<20;i++){s.Gamepad.sThumbRX=-14521;assert(filter.transform(3,0,&s,true,centers)==ERROR_DEVICE_NOT_CONNECTED && s.Gamepad.sThumbRX==0);}
 s={};s.Gamepad.sThumbRX=18000;s.Gamepad.wButtons=XINPUT_GAMEPAD_LEFT_THUMB|XINPUT_GAMEPAD_RIGHT_THUMB;s.Gamepad.bLeftTrigger=255;
 assert(filter.transform(1,0,&s,true,centers)==0 && s.Gamepad.sThumbRX==18000 && s.Gamepad.wButtons==0xc0 && s.Gamepad.bLeftTrigger==255);
 DWORD moved=s.dwPacketNumber;
 assert(filter.transform(1,ERROR_DEVICE_NOT_CONNECTED,&s,true,centers)==0 && s.Gamepad.sThumbRX==0 && s.dwPacketNumber!=moved);
 assert(filter.transform(1,ERROR_DEVICE_NOT_CONNECTED,&s,true,centers)==ERROR_DEVICE_NOT_CONNECTED && filter.device==2);
 s.Gamepad.wButtons=XINPUT_GAMEPAD_A;
 assert(filter.transform(0,0,&s,true,centers)==0 && s.Gamepad.wButtons==0);
 s.Gamepad.sThumbRX=22000;
 assert(filter.transform(1,0,&s,true,centers)==0 && s.Gamepad.sThumbRX==22000); // original slot reconnects
 assert(filter.transform(1,0,&s,false,centers)==0 && s.Gamepad.sThumbRX==0);
 SingleInput calibrated;assert(calibrated.accept("PBZSINGLE1 t 4","t"));
 s={};s.Gamepad.sThumbRX=-14521;
 assert(calibrated.transform(3,0,&s,true,centers)==0 && s.Gamepad.sThumbRX==0);
 s.Gamepad.sThumbRX=32767;calibrated.transform(3,0,&s,true,centers);assert(s.Gamepad.sThumbRX==32767);
 s.Gamepad.sThumbRX=-32768;calibrated.transform(3,0,&s,true,centers);assert(s.Gamepad.sThumbRX==-32767);
 SingleInput keyboard;keyboard.accept("PBZSINGLE1 t 0","t");
 for(int i=0;i<4;i++){s={};s.Gamepad.wButtons=0xffff;keyboard.transform(i,0,&s,true,centers);assert(s.Gamepad.wButtons==0);assert(keyboard.transform(i,0,&s,true,centers)==ERROR_DEVICE_NOT_CONNECTED);}
 SingleInput disabled;s={};s.Gamepad.sThumbRX=-14521;
 assert(disabled.transform(3,0,&s,true,centers)==0 && s.Gamepad.sThumbRX==-14521); // multiplayer untouched
 assert(filter.transform(4,ERROR_DEVICE_NOT_CONNECTED,&s,true,centers)==ERROR_DEVICE_NOT_CONNECTED);
 assert(filter.transform(1,ERROR_BAD_ARGUMENTS,nullptr,true,centers)==ERROR_BAD_ARGUMENTS);
 std::cout<<"PASS: single input isolation, calibrated center/endpoints, normal buttons, focus, reconnect, stale protocol, keyboard and inactive pass-through\n";
}
