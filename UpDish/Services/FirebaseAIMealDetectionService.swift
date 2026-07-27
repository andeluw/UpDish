//
//  FirebaseAIMealDetectionService.swift
//  UpDish
//
//  Created by Andrew Wallace on 19/07/26.
//

import FirebaseAILogic
import UIKit

final class FirebaseAIMealDetectionService: MealDetectionService {
    private let model: GenerativeModel

    private static let systemInstruction = """
        Analisis satu foto makanan untuk menghasilkan nama menu, komponen makanan
        yang terlihat, dan perkiraan proporsi visual setiap komponen.

        Aturan nama menu:
        - Gunakan nama makanan yang umum, singkat, alami, dan mudah dipahami
          dalam Bahasa Indonesia.
        - mealName harus berupa nama hidangan, bukan deskripsi foto, wadah,
          atau cara penyajiannya.
        - Jangan memasukkan kata seperti "bowl", "piring", "mangkuk", atau
          "wadah" ke dalam mealName.
        - mealName tidak harus menyebutkan seluruh komponen. Gunakan nama hidangan
          yang paling umum atau ringkasan singkat dari komponen utamanya.

        Aturan proporsi:
        - Perkirakan portionPercentage berdasarkan proporsi visual setiap komponen
          terhadap keseluruhan satu sajian makanan yang terlihat.
        - Jangan memperkirakan berdasarkan berat, kalori, kandungan gizi,
          atau ukuran wadah.
        - Jika satu sajian ditempatkan pada beberapa piring, mangkuk, atau wadah,
          gabungkan seluruh makanan tersebut sebagai satu kesatuan.
        - Total portionPercentage dari seluruh komponen pada seluruh wadah harus
          tepat 100. Jangan menghitung setiap piring atau mangkuk sebagai 100%
          secara terpisah.
        - Gunakan persentase bilangan bulat.
        - Setelah membulatkan persentase, sesuaikan hasil akhirnya agar total
          seluruh portionPercentage tetap tepat 100.
        - Dasarkan perkiraan hanya pada jumlah makanan yang terlihat.
        - Jangan menebak volume makanan yang tersembunyi di dalam mangkuk,
          tertutup komponen lain, atau tidak terlihat jelas.

        Aturan pemilihan komponen:
        - Setiap bagian makanan hanya boleh dihitung satu kali.
        - Jangan membuat komponen yang duplikat atau saling tumpang tindih.
        - Sertakan hanya komponen yang terlihat jelas dan dapat diperkirakan
          porsinya secara terpisah.
        - Abaikan saus, sambal, kecap, garnish, taburan, atau pelengkap lain
          jika porsinya kecil dan tidak dapat diperkirakan secara terpisah.
        - Jika pelengkap tersebut terlihat jelas dan memiliki proporsi visual
          yang bermakna, tuliskan sebagai komponen tersendiri.
        - Analisis seluruh makanan yang terlihat dan tampak menjadi bagian dari
          satu sajian yang sama, meskipun ditempatkan pada piring, mangkuk,
          atau wadah yang berbeda.
        - Buah atau makanan pendamping yang disajikan terpisah tetap dicantumkan
          jika terlihat jelas dan merupakan bagian dari sajian yang sama.
        - Jangan mencantumkan makanan atau minuman lain di latar belakang yang
          tidak tampak sebagai bagian dari sajian utama.
        - Abaikan piring, mangkuk, alat makan, tangan, kemasan, meja,
          dan latar belakang.
        - Jangan menebak bahan yang tersembunyi atau tidak dapat dibedakan
          secara visual.
        - Jika bahan-bahan menyatu dalam satu hidangan dan batas porsinya tidak
          dapat diperkirakan secara visual, gunakan nama hidangan tersebut sebagai
          satu komponen.
        - Jangan menghitung bahan di dalam hidangan campuran tersebut kembali
          sebagai komponen terpisah.
        - Jika makanan disajikan terpisah dan memiliki batas visual yang jelas,
          tuliskan sebagai komponen yang berbeda.
        - Jika tidak ada makanan yang dapat dikenali dengan jelas,
          kembalikan mealName kosong dan components kosong.

        Contoh keputusan:

        1. Jika nasi putih, ayam goreng, dan tumis sayur terlihat sebagai bagian
           yang terpisah:
           - Nama menu: "Nasi Ayam Goreng dan Tumis Sayur"
           - Komponen: "Nasi Putih", "Ayam Goreng", dan "Tumis Sayur"

        2. Jika soto ayam disajikan dengan nasi putih yang terpisah:
           - Nama menu: "Soto Ayam dengan Nasi"
           - Komponen: "Soto Ayam" dan "Nasi Putih"
           - Jangan menuliskan "Ayam" secara terpisah karena ayam sudah menjadi
             bagian dari "Soto Ayam".

        3. Jika nasi goreng memiliki bahan-bahan yang tercampur dan tidak dapat
           diperkirakan porsinya secara terpisah, tetapi telur mata sapi terlihat
           jelas di atasnya:
           - Nama menu: "Nasi Goreng Telur"
           - Komponen: "Nasi Goreng" dan "Telur Mata Sapi"
           - Jangan memisahkan nasi, bumbu, atau potongan sayur kecil di dalam
             nasi goreng menjadi komponen tersendiri.

        4. Jika nasi putih, ayam goreng, tumis sayur, dan sedikit sambal terlihat:
           - Komponen: "Nasi Putih", "Ayam Goreng", dan "Tumis Sayur"
           - Abaikan sambal jika porsinya terlalu kecil untuk diperkirakan
             secara terpisah.

        5. Jika nasi berada di piring utama, sop sayur berada di mangkuk terpisah,
           dan potongan buah berada di piring kecil, tetapi semuanya merupakan
           bagian dari satu sajian:
           - Nama menu: "Nasi dengan Sop Sayur"
           - Komponen: "Nasi Putih", "Sop Sayur", dan nama buah yang terlihat
           - Hitung seluruh komponen sebagai satu sajian dengan satu total 100%.
           - Jangan memberikan total 100% untuk nasi, 100% untuk sop, dan 100%
             untuk buah secara terpisah.

        6. Jika nasi, ayam, dan sayur berada di piring utama, sedangkan buah berada
           di wadah terpisah tetapi masih merupakan bagian dari sajian yang sama:
           - mealName tidak harus menyebutkan buah.
           - Komponen tetap mencantumkan nama buah yang terlihat.

        7. Jika terlihat salad sayur di dalam mangkuk:
           - Nama menu: "Salad Sayur"
           - Jangan menggunakan nama seperti "Bowl Salad Sayur",
             "Mangkuk Salad Sayur", atau deskripsi wadah lainnya.
        """

    init() {
        let responseSchema = Schema.object(
            properties: [
                "mealName": .string(),
                "components": .array(
                    items: .object(
                        properties: [
                            "name": .string(),
                            "portionPercentage": .integer(),
                        ]
                    )
                ),
            ]
        )

        let ai = FirebaseAI.firebaseAI(
            backend: .googleAI()
        )

        model = ai.generativeModel(
            modelName: "gemini-3.1-flash-lite",
            generationConfig: GenerationConfig(
                responseMIMEType: "application/json",
                responseSchema: responseSchema
            ),
            systemInstruction: ModelContent(
                role: "system",
                parts: Self.systemInstruction
            )
        )
    }

    func detect(from image: UIImage) async throws -> MealDraft {
        try Task.checkCancellation()
        
        let prompt = """
            Analisis makanan pada foto ini sesuai instruksi yang diberikan.
            """

        let response = try await model.generateContent(
            image,
            prompt
        )
        
        try Task.checkCancellation()

        guard
            let jsonText = response.text,
            let jsonData = jsonText.data(using: .utf8)
        else {
            throw MealDetectionError.emptyResponse
        }

        let decodedResponse = try JSONDecoder().decode(
            DetectionResponse.self,
            from: jsonData
        )

        let components = decodedResponse.components.compactMap {
            component -> MealComponent? in

            let trimmedName = component.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !trimmedName.isEmpty else {
                return nil
            }

            return MealComponent(
                name: trimmedName,
                portionPercentage: min(
                    100,
                    max(1, component.portionPercentage)
                )
            )
        }
        guard !components.isEmpty else {
            throw MealDetectionError.noFoodDetected
        }

        let mealName = decodedResponse.mealName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !mealName.isEmpty else {
            throw MealDetectionError.invalidResponse
        }

        return MealDraft(
            mealName: mealName,
            components: components
        )
    }
}

extension FirebaseAIMealDetectionService {
    fileprivate struct DetectionResponse: Decodable {
        let mealName: String
        let components: [DetectedComponent]
    }

    fileprivate struct DetectedComponent: Decodable {
        let name: String
        let portionPercentage: Int
    }
}

enum MealDetectionError: LocalizedError {
    case emptyResponse
    case noFoodDetected
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Hasil analisis belum tersedia. Silakan coba lagi."
        case .noFoodDetected:
            return
                "Makanan belum dapat dikenali. Pastikan seluruh makanan terlihat jelas dan pencahayaan cukup."
        case .invalidResponse:
            return
                "Hasil analisis tidak dapat diproses. Silakan coba lagi dengan foto yang lebih jelas."
        }
    }
}
