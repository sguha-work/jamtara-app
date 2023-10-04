import json
import re


class CsvParser:
    __trimTrailingWhiteSpacesFromHeader = True
    __trimUnsupportedCharectersFromHeader = True

    def __init__(
        self,
        fileNames,
        trimTrailingWhiteSpacesFromHeader=True,
        trimUnsupportedCharectersFromHeader=True,
    ):
        self.__trimTrailingWhiteSpacesFromHeader = trimTrailingWhiteSpacesFromHeader
        self.__trimUnsupportedCharectersFromHeader = trimUnsupportedCharectersFromHeader
        if fileNames.find(","):
            self.csvFileName = fileNames.split(",")
        else:
            self.csvFileName = []
            self.csvFileName.push(fileNames)

    def __getJSONObjectFromSingleFile(self, fileName):
        try:
            openedFile = open(fileName, encoding='utf-8-sig')
        except:
            print("Unable to process file ")
            return False
        outputJSONObject = []
        linesFromFile = openedFile.readlines()
        headers = linesFromFile[0].split(",")
        if self.__trimTrailingWhiteSpacesFromHeader:
            for index, header in enumerate(headers):
                if self.__trimUnsupportedCharectersFromHeader:
                    headers[index] = re.sub("[^A-Za-z0-9_\s]", "", header)
                    headers[index].rstrip('\n').lstrip('\n')
                headers[index] = header.lstrip().rstrip()
                headers[index] = headers[index].strip('.')

        for index, individualLine in enumerate(linesFromFile):
            if index == 0:
                continue
            else:
                data = individualLine.split(",")
                obj = {}
                for objIndex, datum in enumerate(data):
                    obj[headers[objIndex]] = datum
                outputJSONObject.append(obj)
        return outputJSONObject

    def getJSONData(self):
        if len(self.csvFileName) == 1:
            data = self.__getJSONObjectFromSingleFile(self.csvFileName[0])
            if data == False:
                return False
            else:
                return json.dumps(data)
        else:
            outputJSON = {}
            for individualFile in self.csvFileName:
                data = self.__getJSONObjectFromSingleFile(individualFile)
                if data == False:
                    outputJSON[individualFile] = ""
                else:
                    outputJSON[individualFile] = data
            return json.dumps(outputJSON)
