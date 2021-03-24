(function (DurinMedia) {
    var Utility = {};
    DurinMedia.Utility = Utility;
    Utility.displayIconInView = function (record) {
        return [JSON.parse(record).media_logo_url_Value];
    }
}(window.DurinMedia = window.DurinMedia || {}))