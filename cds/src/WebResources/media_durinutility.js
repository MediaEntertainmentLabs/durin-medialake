(function (DurinMedia) {
    var Utility = {};
    DurinMedia.Utility = Utility;
    Utility.displayIconInView = function (a, b, c) {
        return [JSON.parse(a).media_logo_url_Value];
    }

    Utility.NavigateTo = function (selectedid, entity, attribute) {
        fetch(Xrm.Utility.getGlobalContext().getClientUrl() + `/api/data/v9.1/${entity}(${selectedid.replace(/[{}]/g, '')})/${attribute}`)
            .then(res => res.json())
            .then(data => {
                location.href = data.value;
            })
    }
}(window.DurinMedia = window.DurinMedia || {}))