module.exports = (dataToValidate, model)=>{
    const defaultValueForRules = {
        type: {
            default: false
        },
        required: {
            default: false
        }
    }
    let reconstructedModel = {};
    model.forEach((individualModel)=>{
        reconstructedModel[individualModel.name] = individualModel;
    });
    const attributeData = Object.keys(reconstructedModel);
    let flag = true;
    attributeData.forEach((attribute)=>{
        const valueToCheck = dataToValidate[attribute];
        const validateLogic = reconstructedModel[attribute].validate;
        if(validateLogic) {
            const logicNameList = Object.keys(validateLogic);
            
        }
    });
}
