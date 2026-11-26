#pragma once
// Single-player input only. No pawn, viewport, AI or multiplayer state changes.
// Included inside namespace partyinput after the shared calibration helpers.
struct SingleInput {
    bool enabled=false;
    int device=-1; // 0 keyboard/mouse; 1..4 selected physical XInput slot.
    XINPUT_GAMEPAD delivered[4]{};
    DWORD packets[4]{};
    bool releaseSent[4]{};
    bool accept(const std::string& text,const std::string& token) {
        std::istringstream input(text);std::string magic,session,value,extra;
        if(text.size()>160 || !(input>>magic>>session>>value) || input>>extra ||
           magic!="PBZSINGLE1" || session!=token || value.size()!=1 || value[0]<'0' || value[0]>'4')return false;
        const int chosen=value[0]-'0';
        if(enabled)return chosen==device; // A disconnect cannot reassign the seat.
        enabled=true;device=chosen;return true;
    }
    DWORD transform(DWORD index,DWORD result,XINPUT_STATE* state,bool focused,const Calibration* centers) {
        if(!enabled || index>=4 || !state)return result;
        auto publish=[&](const XINPUT_GAMEPAD& pad) {
            if(!packets[index] || memcmp(&pad,&delivered[index],sizeof(pad))) {
                delivered[index]=pad;++packets[index];
            }
            state->Gamepad=pad;state->dwPacketNumber=packets[index];
            return DWORD(ERROR_SUCCESS);
        };
        if(int(index)+1!=device || result!=ERROR_SUCCESS) {
            // Release any input delivered by the engine before hook installation,
            // then report the unselected/disconnected device as disconnected.
            if(!releaseSent[index]){releaseSent[index]=true;return publish({});}
            state->Gamepad={};return ERROR_DEVICE_NOT_CONNECTED;
        }
        releaseSent[index]=false;
        if(!focused)return publish({});
        auto pad=state->Gamepad;const auto& k=centers[index];
        stick(pad.sThumbLX,pad.sThumbLY,k.center[0],k.center[1],k.dead[0]);
        stick(pad.sThumbRX,pad.sThumbRY,k.center[2],k.center[3],k.dead[1]);
        return publish(pad); // All ordinary buttons/triggers pass through unchanged.
    }
};
inline SingleInput single;
