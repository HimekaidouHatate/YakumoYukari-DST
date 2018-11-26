local assets = 
{
   Asset("ANIM", "anim/barrifield.zip")
}

local function kill_fx(inst)
    inst.AnimState:PlayAnimation("close")
    inst.components.lighttweener:StartTween(nil, 0, .9, 0.9, nil, .2)
    inst:DoTaskInTime(0.6, function() inst:Remove() end)    
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddNetwork()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

    anim:SetBank("forcefield")
    anim:SetBuild("barrifield")
    anim:PlayAnimation("open")
    anim:PushAnimation("idle_loop", true)

    inst:AddComponent("lighttweener")
    local light = inst.entity:AddLight()
    inst.components.lighttweener:StartTween(light, 0, .9, 0.9, {1,1,1}, 0)
    inst.components.lighttweener:StartTween(nil, 1.6, .9, 0.9, nil, .2)

    inst.kill_fx = kill_fx

    sound:PlaySound("dontstarve/wilson/forcefield_LP", "loop")

    return inst
end

return Prefab( "common/barrierfield_fx", fn, assets) 