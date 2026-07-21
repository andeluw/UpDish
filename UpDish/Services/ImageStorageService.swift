//
//  ImageStorageService.swift
//  UpDish
//
//  Created by Andrew Wallace on 21/07/26.
//

import UIKit

struct ImageStorageService {
    private let fileManager = FileManager.default

    func save(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageStorageError.encodingFailed
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = try imagesDirectory()
            .appending(path: fileName)

        try data.write(
            to: fileURL,
            options: .atomic
        )

        return fileName
    }

    func load(named fileName: String) -> UIImage? {
        guard let directory = try? imagesDirectory() else {
            return nil
        }

        let fileURL = directory.appending(path: fileName)

        return UIImage(contentsOfFile: fileURL.path(percentEncoded: false))
    }

    func delete(named fileName: String) throws {
        let fileURL = try imagesDirectory()
            .appending(path: fileName)

        guard
            fileManager.fileExists(atPath: fileURL.path(percentEncoded: false))
        else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    private func imagesDirectory() throws -> URL {
        let applicationSupportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let directory =
            applicationSupportDirectory
            .appending(
                path: "MealImages",
                directoryHint: .isDirectory
            )

        if !fileManager.fileExists(
            atPath: directory.path(percentEncoded: false)
        ) {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }

        return directory
    }
}

enum ImageStorageError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Foto makanan gagal disimpan."
        }
    }
}
