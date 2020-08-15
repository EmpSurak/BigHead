#include "timed_execution/timed_execution.as"
#include "timed_execution/repeating_delayed_job.as"
#include "timed_execution/char_damage_job.as"
#include "timed_execution/level_event_job.as"

const string _bighead_key = "BigHead";

TimedExecution timer;

void Init(string level_name){
    timer.Add(RepeatingDelayedJob(1.0f, function(){
        RegisterNewCharacters();
        return true;
    }));

    timer.Add(LevelEventJob("post_reset", function(_params){
        ResetExistingCharacters();
        return true;
    }));
}

void ReceiveMessage(string msg){
    timer.AddLevelEvent(msg);
}

void Update() {
    timer.Update();
}

bool HasFocus(){
    return false;
}

void DrawGUI() {}

void RegisterNewCharacters(){
    uint num = GetNumCharacters();
    for(uint i = 0; i < num; ++i){
        MovementObject @_char = ReadCharacter(i);
        Object @_obj = ReadObjectFromID(_char.GetID());
        ScriptParams @_params = _obj.GetScriptParams();

        if(_params.HasParam(_bighead_key)){
            continue;
        }
        SetInitialBigHead(_params);

        timer.Add(CharDamageJob(_char.GetID(), function(_char, _p_blood, _p_permanent){
            if(_p_blood > _char.GetFloatVar("blood_health") && _p_blood > 0){
                ApplyDamage(_char, abs(_p_blood - _char.GetFloatVar("blood_health")));
            }
            if(_p_permanent > _char.GetFloatVar("permanent_health") && _p_permanent > 0){
                ApplyDamage(_char, abs(_p_permanent - _char.GetFloatVar("permanent_health")));
            }
            return true;
        }));
    }
}

void ResetExistingCharacters(){
    uint num = GetNumCharacters();
    for(uint i = 0; i < num; ++i){
        MovementObject @_char = ReadCharacter(i);
        Object @_obj = ReadObjectFromID(_char.GetID());
        ScriptParams @_params = _obj.GetScriptParams();

        if(!_params.HasParam(_bighead_key)){
            continue;
        }

        SetInitialBigHead(_params);
    }
}

void SetInitialBigHead(ScriptParams@ _params){
    float default_value = 1.0f;
    if(_params.HasParam("Fat")){
        default_value = _params.GetFloat("Fat") * 2.0f;
    }
    _params.SetFloat(_bighead_key, default_value);
}

void ApplyDamage(MovementObject@ _char, float damage){
    Object @_obj = ReadObjectFromID(_char.GetID());
    ScriptParams @_params = _obj.GetScriptParams();

    float total_size = _params.GetFloat(_bighead_key) + damage;
    _params.SetFloat(_bighead_key, total_size);

    InflateBone("head", _char, total_size);
    InflateBone("leftear", _char, total_size);
    InflateBone("rightear", _char, total_size);
}

void InflateBone(string name, MovementObject@ _char, float value){
    if(!_char.rigged_object().skeleton().IKBoneExists(name)){
        return;
    }

    int bone = _char.rigged_object().skeleton().IKBoneStart(name);
    if(bone < 0){
        return;
    }

    int len = _char.rigged_object().skeleton().IKBoneLength(name);
    for(int i = bone; i < bone+len; i++){
        _char.rigged_object().skeleton().SetBoneInflate(i, value);
    }
}
